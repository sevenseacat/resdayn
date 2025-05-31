defmodule Resdayn.Importer.Record.Quest do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    records
    |> chunked_dialogues(:journal)
    |> Enum.map(fn {topic, responses} ->
      name_response = Enum.find(responses, fn resp -> resp.data[:quest_name] end)

      if name_response do
        %{id: topic.data.id, name: name_response.data.content}
      else
        %{id: topic.data.id, name: topic.data.id}
      end
    end)
    |> Enum.filter(& &1)
    |> separate_for_import(Resdayn.Codex.Dialogue.Quest)
  end
end
