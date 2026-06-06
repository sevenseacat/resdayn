defmodule Resdayn.QuestAnalyzer.Extractor.Items do
  @moduledoc """
  Extractors for item involvement across a quest.

  Each public function takes a `%LoadedData{}` and returns a list of
  involvement-row maps shaped to match
  `Resdayn.Codex.QuestAnalysis.ItemInvolvement`:

      %{
        quest_id: <player-concept Quest id, downcased>,
        quest_version_id: <per-ESM record id, downcased>,
        object_id: <ReferencableObject id, downcased>,
        reason: <:required | :surrendered | :received | :placed | :item_mention>,
        dialogue_response_id: <Response.id, downcased> | nil,
        dialogue_response_topic_id: <Response.topic_id, downcased> | nil,
        script_id: <Script.id, downcased> | nil
      }

  The subject is always a single `object_id` (the `ReferencableObject` unified
  key). Exactly one of `(dialogue_response_id + dialogue_response_topic_id)` /
  `script_id` is set (the source). All id fields are downcased via `str/1`.
  """

  import Resdayn.QuestAnalyzer.Helpers
  alias Resdayn.QuestAnalyzer.LoadedData

  # Condition functions whose `:arg` is an item id. All take `:string_arg` per
  # the ScriptParser function table.
  @item_condition_functions ~w(item_count has_item_equipped has_soul_gem)a

  # ReferencableObject types that represent inventoriable items. NPC, creature,
  # static_object, container, etc. are intentionally excluded — those are
  # subjects of other involvement tables.
  @item_object_types ~w(
    weapon armor clothing book potion ingredient
    alchemy_apparatus tool miscellaneous_item
  )a

  # Parsed effect functions that name an item via `:item_id`. Names match the
  # atoms emitted by `Resdayn.QuestAnalyzer.ScriptParser` (snake_case, e.g.
  # `additem` → `:add_item`). Equip/unequip aren't parsed as effects (only as
  # conditions), so they're absent here — a parser-side gap to revisit.
  @item_effect_functions ~w(add_item remove_item drop_item place_at_pc place_item)a

  @doc """
  Emit a `:required` row for every (quest, item) pair where a condition on a
  quest-touching source reads the item's count or equipped status.

  Walks both sides of each condition, since compound conditions can put a
  function reference on the right (e.g. `getitemcount "x" > getitemcount "y"`).
  Skips conditions whose function isn't item-referencing and ids that don't
  resolve to an item-typed `ReferencableObject`.
  """
  def required_items(%LoadedData{} = data) do
    from_dialogue =
      Enum.flat_map(Map.values(data.dialogue_responses), fn response ->
        Enum.uniq(
          condition_rows(response.script_content, data, dialogue_source(response)) ++
            info_condition_rows(response, data)
        )
      end)

    from_scripts =
      Enum.flat_map(data.scripts, fn {script_id, parsed_commands} ->
        Enum.uniq(
          condition_rows(parsed_commands, data, %{
            dialogue_response_id: nil,
            dialogue_response_topic_id: nil,
            script_id: str(script_id)
          })
        )
      end)

    from_dialogue ++ from_scripts
  end

  defp condition_rows(parsed_commands, data, source_fields) do
    for command <- parsed_commands,
        {:ok, qv} <- [Map.fetch(data.quest_versions, command.quest_id)],
        not is_nil(qv.quest_id),
        condition <- command.conditions,
        object_id <- referenced_items(condition, data.referencable_objects) do
      qv
      |> base_row(object_id, :required)
      |> Map.merge(source_fields)
    end
  end

  # Walk both sides of a parsed condition for item-referencing function calls.
  # Returns the validated, downcased item ids; an empty list if neither side
  # references an item.
  defp referenced_items(%{left: left, right: right}, ro_types) do
    for side <- [left, right],
        id <- item_id_from_expression(side, ro_types),
        do: id
  end

  # The script parser falls back to `%{function: :unknown, content: ...}` when
  # a condition uses a function it doesn't know how to parse (e.g.
  # `getspelleffects`). Those carry no structured arg, so nothing item-related
  # can be extracted.
  defp referenced_items(_unrecognised, _ro_types), do: []

  # Walk INFO-level conditions on a dialogue response — the `Response.conditions`
  # array of `%Dialogue.Response.Condition{function: ..., name: ..., ...}`
  # entries. These gate the response from being shown at all, independent of
  # any `if/then` inside `script_content`. The `:item` function maps directly
  # to a `:required` involvement against `name`. We attribute the condition to
  # every quest the response touches via its parsed script content — INFO
  # conditions don't name a quest themselves, but they're gates on whatever
  # journal-setting the response performs.
  defp info_condition_rows(response, data) do
    for parsed_quest_id <- response.script_content |> Enum.map(& &1.quest_id) |> Enum.uniq(),
        {:ok, qv} <- [Map.fetch(data.quest_versions, parsed_quest_id)],
        not is_nil(qv.quest_id),
        condition <- response.conditions || [],
        object_id <- info_item_id(condition, data.referencable_objects) do
      qv
      |> base_row(object_id, :required)
      |> Map.merge(dialogue_source(response))
    end
  end

  defp info_item_id(%{function: :item, name: name}, ro_types) when is_binary(name) do
    key = str(name)

    case Map.fetch(ro_types, key) do
      {:ok, type} when type in @item_object_types -> [key]
      _ -> []
    end
  end

  defp info_item_id(_other, _ro_types), do: []

  @doc """
  Emit a row for every item named by an item-mutating effect on a quest-touching
  source. The reason is derived from the effect's function and subject:

      add_item    + subject :player       → :received
      add_item    + subject :self/NPC/etc → :placed
      remove_item + subject :player       → :surrendered
      remove_item + subject anything else → :item_mention
      place_at_pc / place_item            → :placed
      drop_item                           → :item_mention

  Within a single source, identical rows collapse via the per-source dedup.
  Effects naming an `item_id` that doesn't resolve to an item-typed
  ReferencableObject are skipped.

  Effects where the *subject* is itself an item (e.g. `enable "myitem"`) are a
  separate angle on item involvement not yet covered — captured here is only
  the `item_id`-bearing effect set.
  """
  def effect_items(%LoadedData{} = data) do
    from_dialogue =
      Enum.flat_map(Map.values(data.dialogue_responses), fn response ->
        Enum.uniq(effect_rows(response.script_content, data, dialogue_source(response)))
      end)

    from_scripts =
      Enum.flat_map(data.scripts, fn {script_id, parsed_commands} ->
        Enum.uniq(
          effect_rows(parsed_commands, data, %{
            dialogue_response_id: nil,
            dialogue_response_topic_id: nil,
            script_id: str(script_id)
          })
        )
      end)

    from_dialogue ++ from_scripts
  end

  defp effect_rows(parsed_commands, data, source_fields) do
    for command <- parsed_commands,
        {:ok, qv} <- [Map.fetch(data.quest_versions, command.quest_id)],
        not is_nil(qv.quest_id),
        effect <- command.effects,
        {object_id, reason} <- effect_item_classification(effect, data) do
      qv
      |> base_row(object_id, reason)
      |> Map.merge(source_fields)
    end
  end

  defp effect_item_classification(effect, data) do
    with %{function: function} when function in @item_effect_functions <- effect,
         {:ok, item_id} when is_binary(item_id) <- Map.fetch(effect, :item_id),
         key <- str(item_id),
         {:ok, type} when type in @item_object_types <-
           Map.fetch(data.referencable_objects, key) do
      [{key, effect_reason(function, effect, data)}]
    else
      _ -> []
    end
  end

  defp effect_reason(:add_item, effect, data) do
    case Map.fetch(effect, :subject) do
      {:ok, :player} -> :received
      {:ok, :self} -> :placed
      {:ok, binary} when is_binary(binary) -> placement_or_mention(binary, data)
      _ -> :item_mention
    end
  end

  defp effect_reason(:remove_item, effect, _data) do
    case Map.fetch(effect, :subject) do
      {:ok, :player} -> :surrendered
      _ -> :item_mention
    end
  end

  defp effect_reason(function, _effect, _data) when function in ~w(place_at_pc place_item)a,
    do: :placed

  defp effect_reason(:drop_item, _effect, _data), do: :item_mention

  # An `additem` to a binary subject is `:placed` if the subject resolves to
  # something that can hold an item (NPC, creature, container), otherwise
  # `:item_mention` — we couldn't tell what kind of placement target it was.
  defp placement_or_mention(subject, data) do
    key = str(subject)

    cond do
      Map.has_key?(data.npcs, key) -> :placed
      Map.has_key?(data.creatures, key) -> :placed
      Map.has_key?(data.containers, key) -> :placed
      true -> :item_mention
    end
  end

  defp item_id_from_expression(%{function: function, arg: arg}, ro_types)
       when function in @item_condition_functions and is_binary(arg) do
    key = str(arg)

    case Map.fetch(ro_types, key) do
      {:ok, type} when type in @item_object_types -> [key]
      _ -> []
    end
  end

  defp item_id_from_expression(_other, _ro_types), do: []

  defp base_row(qv, object_id, reason) do
    %{
      quest_id: str(qv.quest_id),
      quest_version_id: str(qv.id),
      object_id: object_id,
      reason: reason
    }
  end

  defp dialogue_source(response) do
    %{
      dialogue_response_id: str(response.id),
      dialogue_response_topic_id: str(response.topic_id),
      script_id: nil
    }
  end
end
