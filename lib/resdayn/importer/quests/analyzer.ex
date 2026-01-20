defmodule Resdayn.Importer.Quests.Analyzer do
  require Ash.Query

  def analyze(quest_ids \\ []) do
    quests = load_quests(quest_ids)

    dialogue_with_scripts = load_dialogue_with_scripts()
    script_journals_by_quest_id = load_scripts()

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

      dialogue_updates =
        dialogue_with_scripts
        |> Enum.filter(fn dialogue ->
          Map.has_key?(dialogue.script_content, downcase(quest.id))
        end)

      npcs =
        Enum.map(dialogue_updates, & &1.speaker_npc_id)
        |> Enum.uniq()
        |> Enum.filter(& &1)

      topics = Enum.map(dialogue_updates, & &1.topic_id) |> Enum.uniq()

      {to_string(quest.id),
       %Resdayn.Codex.QuestAnalysis.Analysis{
         quest_id: to_string(quest.id),
         transitions: script_updates,
         journal_entries: format_journal_entries(quest.journal_entries),
         key_npcs: npcs,
         dialogue_topics: topics
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
