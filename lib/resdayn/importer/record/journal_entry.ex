defmodule Resdayn.Importer.Record.JournalEntry do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> chunked_dialogues(:journal)
      |> Enum.flat_map(fn {topic, entries} ->
        entries
        |> Enum.reverse()
        |> Enum.reject(& &1.data[:quest_name])
        |> Enum.map(fn entry ->
          %{
            id: entry.data.id,
            quest_version_id: topic.data.id,
            index: entry.data[:disposition_or_journal_index],
            content: entry.data[:content],
            finishes_quest: entry.data[:finishes_quest] || false,
            restarts_quest: entry.data[:restarts_quest] || false
          }
        end)
      end)

    %{
      type: :record,
      resource: Resdayn.Catalog.Dialogue.JournalEntry,
      records: processed_records,
      conflict_keys: [:id]
    }
  end
end
