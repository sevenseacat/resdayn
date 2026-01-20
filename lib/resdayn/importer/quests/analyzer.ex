defmodule Resdayn.Importer.Quests.Analyzer do
  require Ash.Query

  def analyze(quest_ids \\ []) do
    quests = load_quests(quest_ids)

    dialogue_with_scripts = load_dialogue_with_scripts()
    script_journals_by_quest_id = load_scripts()
    all_npcs = load_all_npcs()

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

      # NPCs from dialogue + NPCs with quest scripts
      dialogue_npc_ids =
        Enum.map(dialogue_updates, & &1.speaker_npc_id)
        |> Enum.filter(& &1)

      script_npc_ids = Enum.map(npcs_with_quest_scripts, & &1.id)
      all_npc_ids = (dialogue_npc_ids ++ script_npc_ids) |> Enum.uniq()

      # Get locations from NPCs
      dialogue_npcs =
        dialogue_npc_ids
        |> Enum.map(fn npc_id -> Enum.find(all_npcs, &(downcase(&1.id) == downcase(npc_id))) end)
        |> Enum.filter(& &1)

      all_quest_npcs = dialogue_npcs ++ npcs_with_quest_scripts

      locations =
        all_quest_npcs
        |> Enum.flat_map(fn npc -> [npc.cell_name, npc.cell_id] end)
        |> Enum.filter(& &1)
        |> Enum.map(&Ash.CiString.new/1)
        |> Enum.uniq()

      topics = Enum.map(dialogue_updates, & &1.topic_id) |> Enum.uniq()

      items = extract_key_items(dialogue_updates, script_journals_by_quest_id, quest.id)

      {to_string(quest.id),
       %Resdayn.Codex.QuestAnalysis.Analysis{
         quest_id: to_string(quest.id),
         transitions: script_updates,
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

  defp load_all_npcs do
    Resdayn.Codex.World.NPC
    |> Ash.Query.for_read(:read)
    |> Ash.read!(load: [:cell_id, :cell_name])
  end

  # Read all the scripts from the database, and parse them into their journal commands
  # Returns journal commands grouped by quest ID.
  defp load_scripts do
    Resdayn.Codex.Mechanics.Script
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(not is_nil(text))
    |> Ash.read!()
    |> Enum.flat_map(fn script ->
      Resdayn.Importer.Quests.ScriptParser.extract_journal_commands(script.text)
      |> Enum.map(&Map.put(&1, :script_id, script.id))
    end)
    |> Enum.group_by(& &1.quest_id)
  end

  defp load_dialogue_with_scripts do
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
            Resdayn.Importer.Quests.ScriptParser.extract_journal_commands(script_content),
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

  defp downcase(%Ash.CiString{} = value), do: String.downcase(to_string(value))
  defp downcase(value) when is_binary(value), do: String.downcase(value)
end
