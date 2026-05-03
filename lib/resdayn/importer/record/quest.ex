defmodule Resdayn.Importer.Record.Quest do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> chunked_dialogues(:journal)
      |> Enum.map(fn {topic, entries} ->
        name_response = Enum.find(entries, fn resp -> resp.data[:quest_name] end)
        name = if name_response, do: name_response.data.content, else: topic.data.id

        # All faction quest names have formats like "<Faction Name>: Quest Name"
        [faction_id, quest_name] = case String.split(name, ": ") do
          [quest_name] -> [nil, quest_name]
          [faction_name, quest_name] -> [map_faction_name_to_id(faction_name), quest_name]
        end

        %{
          id: topic.data.id,
          name: quest_name,
          faction_id: faction_id
        }
      end)

    %{
      type: :record,
      resource: Resdayn.Codex.Dialogue.Quest,
      records: processed_records,
      conflict_keys: [:id]
    }
  end

  # Edge cases where the faction name doesn't match its ID
  defp map_faction_name_to_id("Fighter's Guild"), do: "Fighters Guild"
  defp map_faction_name_to_id("House " <> name), do: name
  defp map_faction_name_to_id(name), do: name
end
