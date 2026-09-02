defmodule Resdayn.Importer.Record.JournalEntry do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> chunked_dialogues(:journal)
      |> Enum.flat_map(fn {topic, entries} ->
        # Discard the naming entry, and any other name sharing its index -
        # MS_Warlords has two. A stray QSTN on a different index is a real
        # journal entry that Bethesda mis-flagged, so keep it: CO_12a's entry
        # 100 is set by the ColonyAssassin script and the player does see it.
        naming_index =
          case quest_name_response(entries) do
            nil -> nil
            response -> response.data[:disposition_or_journal_index]
          end

        entries
        |> Enum.reject(
          &(&1.data[:quest_name] && &1.data[:disposition_or_journal_index] == naming_index)
        )
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
