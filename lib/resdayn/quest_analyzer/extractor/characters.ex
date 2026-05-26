defmodule Resdayn.QuestAnalyzer.Extractor.Characters do
  @moduledoc """
  Extractors for character involvement (NPCs and creatures) across a quest.

  Each public function takes a `%LoadedData{}` and returns a list of
  involvement-row maps shaped to match
  `Resdayn.Codex.QuestAnalysis.NPCInvolvement`:

      %{
        quest_id: <player-concept Quest id, downcased>,
        quest_version_id: <per-ESM record id, downcased>,
        npc_id: <speaker / bearer / target npc id, downcased>,
        reason: <:dialogue_speaker | :script_bearer | :effect_target | :effect_mention>,
        dialogue_response_id: <Response.id, downcased> | nil,
        dialogue_response_topic_id: <Response.topic_id, downcased> | nil,
        script_id: <Script.id, downcased> | nil
      }

  Exactly one of `(dialogue_response_id + dialogue_response_topic_id)` or
  `script_id` is populated per row, matching the resource's XOR check
  constraint. All id fields are downcased via `str/1`.
  """

  import Resdayn.QuestAnalyzer.Helpers
  alias Resdayn.QuestAnalyzer.LoadedData

  @doc """
  Emit a `:dialogue_speaker` row for every (quest, response) where the
  response's script content sets a journal for that quest. One row per
  (quest, response) pair — multiple journal commands within the same
  response targeting the same quest collapse to one row.

  Skipped:
  - Responses without a `speaker_npc_id` (unrestricted dialogue)
  - Responses whose speaker isn't in `data.npcs` (orphan reference)
  - Responses touching quests not in `data.quest_versions` (filter propagation)
  - QuestVersions without a parent Quest (orphan QuestVersions)
  """
  def dialogue_speakers(%LoadedData{} = data) do
    for response <- Map.values(data.dialogue_responses),
        not is_nil(response.speaker_npc_id),
        {:ok, npc} <- [Map.fetch(data.npcs, str(response.speaker_npc_id))],
        parsed_quest_id <- response.script_content |> Enum.map(& &1.quest_id) |> Enum.uniq(),
        {:ok, qv} <- [Map.fetch(data.quest_versions, parsed_quest_id)],
        not is_nil(qv.quest_id) do
      %{
        quest_id: str(qv.quest_id),
        quest_version_id: str(qv.id),
        npc_id: str(npc.id),
        reason: :dialogue_speaker,
        dialogue_response_id: str(response.id),
        dialogue_response_topic_id: str(response.topic_id),
        script_id: nil
      }
    end
  end

  @doc """
  Emit a `:script_bearer` row for every NPC whose attached script touches
  one or more quests in `data.quest_versions`. One row per (quest, npc) pair —
  if the NPC's script touches multiple quests, one row per quest.

  Skipped:
  - NPCs without an attached `script_id`
  - Quests not in `data.quest_versions` (filter propagation)
  - QuestVersions without a parent Quest (orphan QuestVersions)

  Raises `KeyError` if an NPC references a `script_id` not in `data.scripts` —
  that's a data integrity issue worth crashing on.
  """
  def script_bearers(%LoadedData{} = data) do
    for npc <- Map.values(data.npcs),
        not is_nil(npc.script_id),
        parsed_commands = Map.fetch!(data.scripts, str(npc.script_id)),
        parsed_quest_id <- parsed_commands |> Enum.map(& &1.quest_id) |> Enum.uniq(),
        {:ok, qv} <- [Map.fetch(data.quest_versions, parsed_quest_id)],
        not is_nil(qv.quest_id) do
      %{
        quest_id: str(qv.quest_id),
        quest_version_id: str(qv.id),
        npc_id: str(npc.id),
        reason: :script_bearer,
        dialogue_response_id: nil,
        dialogue_response_topic_id: nil,
        script_id: str(npc.script_id)
      }
    end
  end

  @doc """
  Emit a row for every NPC named as the subject of an effect in a
  quest-touching source. The `reason` is either:

  - `:effect_target` — the effect meaningfully changes the NPC's state
    (enable/disable, positioning, AI commands, combat).
  - `:effect_mention` — softer effects like disposition or fight modifiers.
    The NPC is referenced but not really part of the quest's narrative.

  Within a single source, multiple effects of the same category on the same
  NPC collapse to one row. Significant and mention-level effects on the same
  NPC in the same source produce two rows (different reasons) — the view
  layer can prefer `:effect_target`. Effects targeting `:self`, `:player`,
  or unknown entities are skipped.
  """
  def effect_targets(%LoadedData{} = data) do
    from_dialogue =
      Enum.flat_map(Map.values(data.dialogue_responses), fn response ->
        effect_rows(
          response.script_content,
          data.quest_versions,
          data.npcs,
          %{
            dialogue_response_id: str(response.id),
            dialogue_response_topic_id: str(response.topic_id),
            script_id: nil
          }
        )
      end)

    from_scripts =
      Enum.flat_map(data.scripts, fn {script_id, parsed_commands} ->
        effect_rows(
          parsed_commands,
          data.quest_versions,
          data.npcs,
          %{
            dialogue_response_id: nil,
            dialogue_response_topic_id: nil,
            script_id: str(script_id)
          }
        )
      end)

    from_dialogue ++ from_scripts
  end

  defp effect_rows(parsed_commands, quest_versions, npcs, source_fields) do
    Enum.uniq(
      for command <- parsed_commands,
          {:ok, qv} <- [Map.fetch(quest_versions, command.quest_id)],
          not is_nil(qv.quest_id),
          effect <- command.effects,
          {:ok, subject} when is_binary(subject) <- [Map.fetch(effect, :subject)],
          {:ok, npc} <- [Map.fetch(npcs, str(subject))] do
        Map.merge(source_fields, %{
          quest_id: str(qv.quest_id),
          quest_version_id: str(qv.id),
          npc_id: str(npc.id),
          reason: reason_for(effect.function)
        })
      end
    )
  end

  # State-changing effects that meaningfully involve their target NPC. NPCs hit
  # by anything else with an NPC subject (mod_disposition, mod_fight, etc.) are
  # still captured but with a softer `:effect_mention` reason. The list here is
  # a starting hunch — see docs/quest-analyzer-followups.md for the open
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

  defp reason_for(function) when function in @significant_effects, do: :effect_target
  defp reason_for(_function), do: :effect_mention
end
