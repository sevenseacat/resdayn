defmodule Resdayn.QuestAnalyzer.LoadedData do
  @moduledoc """
  All of the data needed to run the full quest analyzer, pre-loaded and pre-
  prepared. Built once at the start of a run, then threaded through extractors
  that will pick out the relevant information.
  """

  # %QuestVersion{}, with journal_entries + quest_id preloaded
  defstruct quest_versions: [],
            # %{downcased_script_id => raw_script_text}
            scripts_by_id: %{},
            # %Response{} with script_content pre-parsed
            dialogue_responses: []

  require Ash.Query
  require Logger

  import Resdayn.QuestAnalyzer.Helpers
  alias Resdayn.QuestAnalyzer.ScriptParser

  def load(quest_ids \\ []) do
    quest_versions = time(fn -> load_quest_versions(quest_ids) end, "quest versions")
    script_map = time(&load_scripts_by_id/0, "script map")

    %__MODULE__{
      quest_versions: quest_versions,
      scripts_by_id: script_map,
      dialogue_responses:
        time(fn -> load_dialogue_responses(script_map) end, "dialogue responses")
    }
  end

  defp load_quest_versions(quest_ids) do
    query = Ash.Query.for_read(Resdayn.Codex.Dialogue.QuestVersion, :read)

    if quest_ids != [] do
      Ash.Query.filter(query, id in ^quest_ids)
    else
      query
    end
    |> Ash.read!(load: [:journal_entries])
  end

  defp load_scripts_by_id do
    Resdayn.Codex.Mechanics.Script
    |> Ash.read!()
    |> Map.new(fn script -> {str(script.id), script.text} end)
  end

  # Load all relevant dialogue from the database, with parsed script content.
  #
  # Uses the provided script map so that StartScript commands from the dialogue
  # script content can be followed during parsing.
  #
  # eg. dialogue response 2013624711243725845 for TG_LootAldruhnMG uses a nested
  # StartScript to disable all of the NPCs and spawn the required item
  def load_dialogue_responses(script_map) do
    Resdayn.Codex.Dialogue.Response
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(not is_nil(script_content))
    |> Ash.read!()
    |> Enum.map(fn response ->
      Map.update!(response, :script_content, &parse_content(&1, script_map))
    end)
  end

  defp parse_content(content, script_map) do
    ScriptParser.extract_journal_commands(
      content,
      script_map,
      follow_scripts: true
    )
  end

  defp time(func, label) do
    {time, result} = :timer.tc(func, :millisecond)
    Logger.info("Loading #{label}: #{time}ms")
    result
  end
end
