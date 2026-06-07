defmodule Resdayn.QuestAnalyzer.Extractor.Transitions do
  @moduledoc """
  Discover transition rows — one per `Journal "QuestID" N` call site across
  parsed dialogue script_content and standalone scripts.

  Each row records the source (dialogue response or script) that contains
  the call and the `target_index` the call advances the quest to. C1 only
  populates the bare structural fields; precondition extraction (`from_min`/
  `from_max`) is a C2 concern, start/finish flagging is C6.

  Within a single source, multiple `Journal X N` calls at the same index
  collapse via per-source `Enum.uniq` (e.g. defensive against parser
  duplicates). Cross-source duplicates are not possible — each row's
  source uniquely identifies it.
  """

  import Resdayn.QuestAnalyzer.Helpers
  alias Resdayn.QuestAnalyzer.LoadedData

  def discover(%LoadedData{} = data) do
    from_dialogue =
      Enum.flat_map(Map.values(data.dialogue_responses), fn response ->
        Enum.uniq(transition_rows(response.script_content, data, dialogue_source(response)))
      end)

    from_scripts =
      Enum.flat_map(data.scripts, fn {script_id, parsed_commands} ->
        Enum.uniq(
          transition_rows(parsed_commands, data, %{
            dialogue_response_id: nil,
            dialogue_response_topic_id: nil,
            script_id: str(script_id)
          })
        )
      end)

    from_dialogue ++ from_scripts
  end

  defp transition_rows(parsed_commands, data, source_fields) do
    for command <- parsed_commands,
        {:ok, qv} <- [LoadedData.fetch_quest_version(data, command.quest_id)],
        not is_nil(qv.quest_id) do
      %{
        quest_id: str(qv.quest_id),
        quest_version_id: str(qv.id),
        target_index: command.index
      }
      |> Map.merge(source_fields)
    end
  end

  defp dialogue_source(response) do
    %{
      dialogue_response_id: str(response.id),
      dialogue_response_topic_id: str(response.topic_id),
      script_id: nil
    }
  end
end
