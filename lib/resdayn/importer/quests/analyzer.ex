defmodule Resdayn.Importer.Quests.Analyzer do
  require Ash.Query

  alias Resdayn.Importer.Quests.ChoiceChain
  alias Resdayn.Importer.Quests.ItemLocations
  alias Resdayn.Importer.Quests.TopicAvailability

  def analyze(quest_ids \\ []) do
    quests = load_quests(quest_ids)

    script_map = load_script_map()
    dialogue_with_scripts = load_dialogue_with_scripts(script_map)
    script_journals_by_quest_id = load_scripts(script_map)
    all_npcs = load_all_npcs()
    npc_id_set = MapSet.new(all_npcs, fn npc -> downcase(npc.id) end)
    item_locations = load_item_locations()

    # Build topic availability index for inferring from_min bounds
    topic_availability =
      build_topic_availability()
      |> add_script_topic_availability(script_journals_by_quest_id)

    # Build choice presenter index for linking choice-conditioned responses to their parents
    choice_presenters = ChoiceChain.build_index(dialogue_with_scripts)

    Map.new(quests, fn quest ->
      IO.puts("Analyzing #{quest.id}...")

      script_updates =
        Map.get(script_journals_by_quest_id, downcase(quest.id), [])
        |> Enum.map(fn update ->
          %Resdayn.Codex.QuestAnalysis.Transition{
            index: update.index,
            from_max: update.index - 1,
            trigger_type: :script,
            trigger_id: update.script_id
          }
        end)

      # Get script IDs that update this quest
      quest_script_ids =
        script_updates
        |> Enum.map(& &1.trigger_id)
        |> Enum.map(&downcase/1)
        |> MapSet.new()

      # Find NPCs that have these scripts attached
      npcs_with_quest_scripts =
        all_npcs
        |> Enum.filter(fn npc ->
          npc.script_id && MapSet.member?(quest_script_ids, downcase(npc.script_id))
        end)

      dialogue_updates =
        dialogue_with_scripts
        |> Enum.filter(fn dialogue ->
          Map.has_key?(dialogue.script_content, downcase(quest.id))
        end)

      # Build dialogue transitions
      dialogue_transitions =
        dialogue_updates
        |> Enum.flat_map(fn response ->
          quest_commands = Map.get(response.script_content, downcase(quest.id), [])

          quest_commands
          |> Enum.map(fn cmd ->
            {from_min, from_max} = extract_journal_bounds(response.conditions, quest.id)

            # If from_min is nil, check if this is a choice-conditioned response
            from_min = from_min || ChoiceChain.get_from_min(choice_presenters, response, quest.id)

            # If from_min is still nil, check if topic availability constrains it
            from_min = apply_topic_availability_bounds(from_min, response.topic_id, quest.id, topic_availability)

            %Resdayn.Codex.QuestAnalysis.Transition{
              index: cmd.index,
              from_min: from_min,
              from_max: from_max,
              trigger_type: :dialogue_response,
              trigger_id: Ash.CiString.new(to_string(response.id)),
              trigger_topic_id: response.topic_id
            }
          end)
        end)

      all_transitions =
        (script_updates ++ dialogue_transitions)
        |> narrow_from_ranges(quest.journal_entries)

      # NPCs from dialogue + NPCs with quest scripts
      dialogue_npc_ids =
        Enum.map(dialogue_updates, & &1.speaker_npc_id)
        |> Enum.filter(& &1)

      script_npc_ids = Enum.map(npcs_with_quest_scripts, & &1.id)

      # NPCs referenced as subjects in effects (disable, enable, etc.)
      effect_npc_ids = extract_npc_ids_from_effects(dialogue_updates, script_journals_by_quest_id, quest.id, npc_id_set)

      all_npc_ids = (dialogue_npc_ids ++ script_npc_ids ++ effect_npc_ids) |> Enum.uniq()

      # Get locations from NPCs
      all_quest_npcs =
        all_npc_ids
        |> Enum.map(fn npc_id -> Enum.find(all_npcs, &(downcase(&1.id) == downcase(npc_id))) end)
        |> Enum.filter(& &1)

      npc_locations =
        all_quest_npcs
        |> Enum.flat_map(fn npc -> [npc.cell_name, npc.cell_id] end)
        |> Enum.filter(& &1)
        |> Enum.map(&Ash.CiString.new/1)

      topics = Enum.map(dialogue_updates, & &1.topic_id) |> Enum.uniq()

      items = extract_key_items(dialogue_updates, script_journals_by_quest_id, quest.id)

      condition_item_ids = extract_condition_item_ids(dialogue_updates)
      add_item_targets = collect_add_item_targets(dialogue_updates, script_journals_by_quest_id, quest.id)
      item_locations = ItemLocations.get_locations(item_locations, condition_item_ids, add_item_targets)

      locations = (npc_locations ++ item_locations) |> Enum.uniq()

      {to_string(quest.id),
       %Resdayn.Codex.QuestAnalysis.Analysis{
         quest_id: to_string(quest.id),
         transitions: all_transitions,
         journal_entries: format_journal_entries(quest.journal_entries),
         key_npcs: all_npc_ids,
         key_locations: locations,
         dialogue_topics: topics,
         key_items: items
       }}
    end)
  end

  defp load_quests([]) do
    Resdayn.Codex.Dialogue.Quest
    |> Ash.Query.for_read(:read)
    |> Ash.read!(load: [:journal_entries])
  end

  defp load_quests(list) when is_list(list) do
    Resdayn.Codex.Dialogue.Quest
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(id in ^list)
    |> Ash.read!(load: [:journal_entries])
  end

  defp load_item_locations do
    unique_placements = load_unique_placements()
    holders = load_inventory_holders()
    ItemLocations.build(unique_placements, holders)
  end

  # References with exactly 1 cell placement: %{downcased_ref_id => cell_id}
  defp load_unique_placements do
    {:ok, %{rows: rows}} =
      Ecto.Adapters.SQL.query(Resdayn.Repo, """
        SELECT LOWER(reference_id), MIN(cell_id)
        FROM cell_references
        GROUP BY LOWER(reference_id)
        HAVING COUNT(*) = 1
      """)

    Map.new(rows, fn [ref_id, cell_id] -> {ref_id, cell_id} end)
  end

  # Inventory holders grouped by item: %{downcased_item_id => [holder_ref_id]}
  defp load_inventory_holders do
    {:ok, %{rows: rows}} =
      Ecto.Adapters.SQL.query(Resdayn.Repo, """
        SELECT LOWER(object_ref_id), array_agg(DISTINCT LOWER(holder_ref_id))
        FROM inventory_items
        GROUP BY LOWER(object_ref_id)
      """)

    Map.new(rows, fn [item_id, holder_ids] -> {item_id, holder_ids} end)
  end

  defp load_all_npcs do
    Resdayn.Codex.World.NPC
    |> Ash.Query.for_read(:read)
    |> Ash.read!(load: [:cell_id, :cell_name])
  end

  # Build a map of downcased script_id -> text for follow_scripts support
  defp load_script_map do
    Resdayn.Codex.Mechanics.Script
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(not is_nil(text))
    |> Ash.read!()
    |> Map.new(fn script -> {downcase(script.id), script.text} end)
  end

  # Parse all scripts into their journal commands, grouped by quest ID.
  defp load_scripts(script_map) do
    script_map
    |> Enum.flat_map(fn {id, text} ->
      Resdayn.Importer.Quests.ScriptParser.extract_journal_commands(text, script_map, follow_scripts: true)
      |> Enum.map(&Map.put(&1, :script_id, Ash.CiString.new(id)))
    end)
    |> Enum.group_by(& &1.quest_id)
  end

  defp load_dialogue_with_scripts(script_map) do
    Resdayn.Codex.Dialogue.Response
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(not is_nil(script_content))
    |> Ash.read!()
    |> Enum.map(fn response ->
      Map.update!(
        response,
        :script_content,
        fn script_content ->
          Enum.group_by(
            Resdayn.Importer.Quests.ScriptParser.extract_journal_commands(
              script_content, script_map, follow_scripts: true
            ),
            & &1.quest_id
          )
        end
      )
    end)
  end

  defp extract_key_items(dialogue_updates, script_journals_by_quest_id, quest_id) do
    # Items from dialogue response conditions (function: :item)
    condition_items =
      dialogue_updates
      |> Enum.flat_map(fn response ->
        (response.conditions || [])
        |> Enum.filter(fn c -> c.function == :item end)
        |> Enum.map(fn c -> c.name end)
      end)

    # Items from script effects (add_item, remove_item) in dialogue scripts
    dialogue_script_items =
      dialogue_updates
      |> Enum.flat_map(fn response ->
        quest_commands = Map.get(response.script_content, downcase(quest_id), [])

        quest_commands
        |> Enum.flat_map(fn cmd ->
          cmd.effects
          |> Enum.filter(fn e -> e[:function] in [:add_item, :remove_item] end)
          |> Enum.map(fn e -> e[:item_id] end)
        end)
      end)

    # Items from script effects in standalone scripts
    standalone_script_items =
      Map.get(script_journals_by_quest_id, downcase(quest_id), [])
      |> Enum.flat_map(fn cmd ->
        cmd.effects
        |> Enum.filter(fn e -> e[:function] in [:add_item, :remove_item] end)
        |> Enum.map(fn e -> e[:item_id] end)
      end)

    (condition_items ++ dialogue_script_items ++ standalone_script_items)
    |> Enum.filter(& &1)
    |> Enum.reject(fn item -> String.downcase(item) == "gold_001" end)
    |> Enum.map(&Ash.CiString.new/1)
    |> Enum.uniq()
  end

  defp extract_condition_item_ids(dialogue_updates) do
    dialogue_updates
    |> Enum.flat_map(fn response ->
      (response.conditions || [])
      |> Enum.filter(fn c -> c.function == :item end)
      |> Enum.map(fn c -> c.name end)
    end)
    |> Enum.reject(fn item -> String.downcase(item) == "gold_001" end)
    |> Enum.uniq()
  end

  # Collect add_item effect targets: returns %{downcased_item_id => [target_ids]}
  defp collect_add_item_targets(dialogue_updates, script_journals_by_quest_id, quest_id) do
    dialogue_effects =
      dialogue_updates
      |> Enum.flat_map(fn response ->
        Map.get(response.script_content, downcase(quest_id), [])
        |> Enum.flat_map(& &1.effects)
      end)

    script_effects =
      Map.get(script_journals_by_quest_id, downcase(quest_id), [])
      |> Enum.flat_map(& &1.effects)

    (dialogue_effects ++ script_effects)
    |> Enum.filter(fn e -> e[:function] == :add_item and is_binary(e[:subject]) end)
    |> Enum.group_by(fn e -> downcase(e[:item_id]) end, fn e -> e[:subject] end)
  end

  defp extract_npc_ids_from_effects(dialogue_updates, script_journals_by_quest_id, quest_id, npc_id_set) do
    dialogue_effects =
      dialogue_updates
      |> Enum.flat_map(fn response ->
        Map.get(response.script_content, downcase(quest_id), [])
        |> Enum.flat_map(& &1.effects)
      end)

    script_effects =
      Map.get(script_journals_by_quest_id, downcase(quest_id), [])
      |> Enum.flat_map(& &1.effects)

    (dialogue_effects ++ script_effects)
    |> Enum.map(fn e -> e[:subject] end)
    |> Enum.filter(fn subject -> is_binary(subject) and MapSet.member?(npc_id_set, downcase(subject)) end)
    |> Enum.map(&Ash.CiString.new/1)
    |> Enum.uniq()
  end

  defp format_journal_entries(entries) do
    entries
    |> Enum.sort_by(& &1.index)
    |> Enum.map(fn entry ->
      %{
        index: entry.index,
        content: entry.content,
        finish?: entry.finishes_quest,
        restart?: entry.restarts_quest
      }
    end)
  end

  defp extract_journal_bounds(conditions, quest_id) do
    quest_id_lower = downcase(quest_id)

    journal_conditions =
      (conditions || [])
      |> Enum.filter(fn c ->
        c.function == :journal && downcase(c.name) == quest_id_lower
      end)

    from_min =
      journal_conditions
      |> Enum.filter(fn c -> c.operator in [:>=, :>, :=] end)
      |> Enum.map(fn c ->
        value = c.value.value
        if c.operator == :>, do: value + 1, else: value
      end)
      |> Enum.max(fn -> nil end)

    from_max =
      journal_conditions
      |> Enum.filter(fn c -> c.operator in [:<=, :<, :=] end)
      |> Enum.map(fn c ->
        value = c.value.value
        if c.operator == :<, do: value - 1, else: value
      end)
      |> Enum.min(fn -> nil end)

    {from_min, from_max}
  end

  defp build_topic_availability do
    # Load all topic IDs for implicit topic detection
    all_topic_ids =
      Resdayn.Codex.Dialogue.Topic
      |> Ash.Query.for_read(:read)
      |> Ash.read!()
      |> Enum.map(&to_string(&1.id))

    # Load all dialogue responses (not just those with scripts)
    all_responses =
      Resdayn.Codex.Dialogue.Response
      |> Ash.Query.for_read(:read)
      |> Ash.read!()

    TopicAvailability.build(all_responses, all_topic_ids, parallel: true)
  end

  # When a standalone script sets a journal index AND adds a topic, we know
  # that topic becomes available at that journal index.
  defp add_script_topic_availability(topic_availability, script_journals_by_quest_id) do
    entries =
      script_journals_by_quest_id
      |> Enum.flat_map(fn {quest_id, commands} ->
        Enum.flat_map(commands, fn cmd ->
          cmd.effects
          |> Enum.filter(fn e -> e[:function] == :add_topic end)
          |> Enum.map(fn e ->
            %{
              topic_id: String.downcase(e[:topic_id]),
              quest_id: quest_id,
              from_min: cmd.index,
              from_max: nil,
              source: :script
            }
          end)
        end)
      end)

    TopicAvailability.add_entries(topic_availability, entries)
  end

  # Narrow from ranges using known journal indices:
  # - If a range (e.g. 10-19) contains only one journal index, pin to that index
  # - If from_max is set but no journal indices exist in 0..from_max, this is the
  #   quest start point (from_min: 0, from_max: 0)
  defp narrow_from_ranges(transitions, journal_entries) do
    known_indices = MapSet.new(journal_entries, & &1.index)

    Enum.map(transitions, fn transition ->
      narrow_from_range(transition, known_indices)
    end)
  end

  defp narrow_from_range(%{from_max: from_max} = transition, known_indices)
       when not is_nil(from_max) do
    from_min = transition.from_min || 0

    indices_in_range =
      known_indices
      |> Enum.filter(fn i -> i >= from_min and i <= from_max end)

    case indices_in_range do
      [] -> %{transition | from_min: 0, from_max: 0}
      [single] -> %{transition | from_min: single, from_max: single}
      _ -> transition
    end
  end

  defp narrow_from_range(transition, _known_indices), do: transition

  defp apply_topic_availability_bounds(from_min, topic_id, quest_id, topic_availability) do
    {topic_from_min, _topic_from_max} = TopicAvailability.get_bounds(topic_availability, topic_id, quest_id)

    case {from_min, topic_from_min} do
      # If we already have a from_min, take the max of the two
      {existing, topic_min} when not is_nil(existing) and not is_nil(topic_min) ->
        max(existing, topic_min)

      # If only topic has a min, use it
      {nil, topic_min} when not is_nil(topic_min) ->
        topic_min

      # Otherwise keep what we have (which may be nil)
      {existing, _} ->
        existing
    end
  end

  defp downcase(%Ash.CiString{} = value), do: String.downcase(to_string(value))
  defp downcase(value) when is_binary(value), do: String.downcase(value)
end
