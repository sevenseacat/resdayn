defmodule Resdayn.QuestAnalyzer.LoadedData do
  @moduledoc """
  All of the data needed to run the full quest analyzer, pre-loaded and pre-
  prepared. Built once at the start of a run, then threaded through extractors
  that will pick out the relevant information.

  Every field is a map keyed by the downcased entity id, so extractors can
  cross-reference in O(1) (e.g. resolving a parsed command's `quest_id` back
  to its `QuestVersion`). When the whole collection is needed for iteration,
  use `Map.values/1`.
  """

  # %QuestVersion{} with journal_entries preloaded
  defstruct quest_versions: %{},
            # [parsed_journal_command] — standalone scripts pre-parsed
            scripts: %{},
            # %Response{} with script_content pre-parsed into journal commands
            dialogue_responses: %{},
            # %NPC{} with cell info preloaded
            npcs: %{}

  require Ash.Query
  require Logger

  import Resdayn.QuestAnalyzer.Helpers
  alias Resdayn.QuestAnalyzer.ScriptParser

  def load(quest_ids \\ []) do
    quest_versions = time(fn -> load_quest_versions(quest_ids) end, "quest versions")
    script_text_map = time(&load_script_text_map/0, "script text")

    %__MODULE__{
      quest_versions: quest_versions,
      scripts: time(fn -> parse_scripts(script_text_map) end, "scripts"),
      dialogue_responses:
        time(fn -> load_dialogue_responses(script_text_map) end, "dialogue responses"),
      npcs: time(&load_npcs/0, "npcs")
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
    |> Map.new(fn qv -> {str(qv.id), qv} end)
  end

  # Build a transient map of raw script text keyed by downcased id. Used as
  # the script_map argument to ScriptParser.extract_journal_commands/3 so that
  # StartScript references can be followed during parsing. Not exposed on
  # LoadedData — once parsing finishes nothing else needs the raw text.
  defp load_script_text_map do
    Resdayn.Codex.Mechanics.Script
    |> Ash.read!()
    |> Map.new(fn script -> {str(script.id), script.text} end)
  end

  defp parse_scripts(script_text_map) do
    script_text_map
    |> perform_async(fn {id, text} ->
      {id, ScriptParser.extract_journal_commands(text, script_text_map, follow_scripts: true)}
    end)
    |> Map.new()
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
    |> Ash.Query.filter(
      ilike(script_content, "%journal%") or ilike(script_content, "%startscript%")
    )
    |> Ash.read!()
    |> perform_async(fn response ->
      Map.update!(response, :script_content, &parse_content(&1, script_map))
    end)
    |> Map.new(fn response -> {str(response.id), response} end)
  end

  defp parse_content(content, script_map) do
    ScriptParser.extract_journal_commands(content, script_map, follow_scripts: true)
  end

  defp load_npcs do
    Resdayn.Codex.World.NPC
    |> Ash.Query.for_read(:read)
    |> Ash.read!(load: [:cell_id])
    |> Map.new(fn npc -> {str(npc.id), npc} end)
  end

  defp perform_async(data, operation) do
    data
    |> Enum.chunk_every(100)
    |> Task.async_stream(
      fn group -> Enum.map(group, &operation.(&1)) end,
      ordered: false,
      timeout: :infinity
    )
    |> Enum.flat_map(&elem(&1, 1))
  end

  defp time(func, label) do
    {time, result} = :timer.tc(func, :millisecond)
    Logger.info("Loading #{label}: #{time}ms")
    result
  end
end
