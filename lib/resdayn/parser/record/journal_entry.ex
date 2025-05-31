defmodule Resdayn.Importer.Record.JournalEntry do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    records
    |> chunked_dialogues(:journal)
    |> Enum.map(fn {topic, entries} ->
      name_response = Enum.find(entries, fn resp -> resp.data[:quest_name] end)

      entries =
        entries
        |> Enum.reverse()
        |> Enum.reject(& &1.data[:quest_name])
        |> Enum.map(fn entry ->
          entry.data
          |> Map.take([:id, :content, :finishes_quest, :restarts_quest])
          |> Map.put(:index, entry.data.disposition_or_journal_index)
        end)

      topic =
        topic.data
        |> Map.take([:id])
        |> Map.put(:entries, entries)

      if name_response do
        Map.put(topic, :name, name_response.data.content)
      else
        topic
      end
    end)
    |> separate_for_import(Resdayn.Codex.Dialogue.Quest, action: :import_relationships)
  end
end
