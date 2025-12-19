defmodule Resdayn.Importer.Record.Quest do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> chunked_dialogues(:journal)
      |> Enum.map(fn {topic, entries} ->
        name_response = Enum.find(entries, fn resp -> resp.data[:quest_name] end)
        name = if name_response, do: name_response.data.content, else: topic.data.id

        %{
          id: topic.data.id,
          name: name
        }
      end)

    %{
      type: :fast_bulk,
      resource: Resdayn.Codex.Dialogue.Quest,
      records: processed_records,
      conflict_keys: [:id]
    }
  end
end
