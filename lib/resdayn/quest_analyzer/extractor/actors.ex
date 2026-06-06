defmodule Resdayn.QuestAnalyzer.Extractor.Actors do
  @moduledoc """
  Extractors for actor involvement (NPCs and creatures) across a quest.

  Each public function takes a `%LoadedData{}` and returns a list of
  involvement-row maps shaped to match
  `Resdayn.Codex.QuestAnalysis.ActorInvolvement`:

      %{
        quest_id: <player-concept Quest id, downcased>,
        quest_version_id: <per-ESM record id, downcased>,
        npc_id: <npc id, downcased> | nil,
        creature_id: <creature id, downcased> | nil,
        reason: <:dialogue_speaker | :script_bearer | :effect_target | :effect_mention>,
        dialogue_response_id: <Response.id, downcased> | nil,
        dialogue_response_topic_id: <Response.topic_id, downcased> | nil,
        script_id: <Script.id, downcased> | nil
      }

  Exactly one of `npc_id` / `creature_id` is set (the subject), and exactly
  one of `(dialogue_response_id + dialogue_response_topic_id)` / `script_id`
  is set (the source). All id fields are downcased via `str/1`.
  """

  import Resdayn.QuestAnalyzer.Helpers
  alias Resdayn.QuestAnalyzer.LoadedData

  @doc """
  Emit a `:dialogue_speaker` row for every (quest, response) where the
  response's script content sets a journal for that quest. The speaker is
  either an NPC (`speaker_npc_id`) or a creature (`speaker_creature_id`).

  Skipped: responses with no speaker, an unknown speaker, no quest match,
  or an orphan QuestVersion.
  """
  def dialogue_speakers(%LoadedData{} = data) do
    for response <- Map.values(data.dialogue_responses),
        {actor_type, actor} <- resolve_speaker(response, data),
        parsed_quest_id <- response.script_content |> Enum.map(& &1.quest_id) |> Enum.uniq(),
        {:ok, qv} <- [LoadedData.fetch_quest_version(data, parsed_quest_id)],
        not is_nil(qv.quest_id) do
      qv
      |> base_row(actor_type, actor, :dialogue_speaker)
      |> Map.merge(dialogue_source(response))
    end
  end

  @doc """
  Emit a `:script_bearer` row for every NPC or creature whose attached script
  touches a quest. One row per (quest, actor) pair.

  Raises `KeyError` if an actor references a `script_id` not in
  `data.scripts` — a data integrity issue worth crashing on.
  """
  def script_bearers(%LoadedData{} = data) do
    bearer_rows(Map.values(data.npcs), :npc, data) ++
      bearer_rows(Map.values(data.creatures), :creature, data)
  end

  defp bearer_rows(actors, actor_type, data) do
    for actor <- actors,
        not is_nil(actor.script_id),
        parsed_commands = LoadedData.fetch_script!(data, actor.script_id),
        parsed_quest_id <- parsed_commands |> Enum.map(& &1.quest_id) |> Enum.uniq(),
        {:ok, qv} <- [LoadedData.fetch_quest_version(data, parsed_quest_id)],
        not is_nil(qv.quest_id) do
      qv
      |> base_row(actor_type, actor, :script_bearer)
      |> Map.merge(script_source(actor))
    end
  end

  # State-changing effects that meaningfully involve their target actor.
  # Actors hit by anything else (mod_disposition, mod_fight, etc.) are still
  # captured but with a softer `:effect_mention` reason. The list here is a
  # starting hunch — see docs/quest-analyzer-followups.md for the open
  # question on the full taxonomy.
  @significant_effects ~w(
    enable
    disable
    position_cell
    position
    ai_follow
    ai_escort
    ai_activate
    ai_travel
    start_combat
  )a

  @doc """
  Emit a row for every actor named as the subject of an effect in a
  quest-touching source. `reason` is `:effect_target` for state-changing
  effects, `:effect_mention` for softer ones (disposition/fight modifiers).

  Within a single source, multiple effects of the same category on the same
  actor collapse to one row. Effects targeting `:self`, `:player`, or
  unknown entities are skipped.
  """
  def effect_targets(%LoadedData{} = data) do
    from_dialogue =
      Enum.flat_map(Map.values(data.dialogue_responses), fn response ->
        effect_rows(response.script_content, data, dialogue_source(response))
      end)

    from_scripts =
      Enum.flat_map(data.scripts, fn {script_id, parsed_commands} ->
        effect_rows(parsed_commands, data, %{
          dialogue_response_id: nil,
          dialogue_response_topic_id: nil,
          script_id: str(script_id)
        })
      end)

    from_dialogue ++ from_scripts
  end

  defp effect_rows(parsed_commands, data, source_fields) do
    Enum.uniq(
      for command <- parsed_commands,
          {:ok, qv} <- [LoadedData.fetch_quest_version(data, command.quest_id)],
          not is_nil(qv.quest_id),
          effect <- command.effects,
          {:ok, subject} <- [Map.fetch(effect, :subject)],
          {:ok, {actor_type, actor}} <- [LoadedData.fetch_actor(data, subject)] do
        qv
        |> base_row(actor_type, actor, reason_for(effect.function))
        |> Map.merge(source_fields)
      end
    )
  end

  # Resolve a dialogue response's speaker to an actor tuple, using whichever
  # speaker field is populated to pick the lookup table.
  defp resolve_speaker(%{speaker_npc_id: id}, data) when not is_nil(id) do
    case LoadedData.fetch_npc(data, id) do
      {:ok, npc} -> [{:npc, npc}]
      :error -> []
    end
  end

  defp resolve_speaker(%{speaker_creature_id: id}, data) when not is_nil(id) do
    case LoadedData.fetch_creature(data, id) do
      {:ok, creature} -> [{:creature, creature}]
      :error -> []
    end
  end

  defp resolve_speaker(_response, _data), do: []

  defp base_row(qv, actor_type, actor, reason) do
    %{quest_id: str(qv.quest_id), quest_version_id: str(qv.id), reason: reason}
    |> Map.merge(subject_fields(actor_type, actor))
  end

  defp subject_fields(:npc, npc), do: %{npc_id: str(npc.id), creature_id: nil}
  defp subject_fields(:creature, creature), do: %{npc_id: nil, creature_id: str(creature.id)}

  defp dialogue_source(response) do
    %{
      dialogue_response_id: str(response.id),
      dialogue_response_topic_id: str(response.topic_id),
      script_id: nil
    }
  end

  defp script_source(actor) do
    %{
      dialogue_response_id: nil,
      dialogue_response_topic_id: nil,
      script_id: str(actor.script_id)
    }
  end

  defp reason_for(function) when function in @significant_effects, do: :effect_target
  defp reason_for(_function), do: :effect_mention
end
