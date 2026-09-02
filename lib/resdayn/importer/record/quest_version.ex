defmodule Resdayn.Importer.Record.QuestVersion do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> chunked_dialogues(:journal)
      |> Enum.map(fn {topic, entries} ->
        # Only emit :name when this pass has a QSTN-flagged INFO
        # (the "quest name" entry). Override records without QSTN — TR_Mainland
        # tweaks to vanilla quests, T_Rules_* infrastructure records — fall
        # through with just :id, which preserves any existing name set
        # by an earlier pass and lets source_file_ids accumulate.
        case quest_name_response(entries) do
          nil ->
            %{id: topic.data.id}

          name_response ->
            %{
              id: topic.data.id,
              name: name_response.data.content
            }
        end
      end)

    %{
      type: :record,
      resource: Resdayn.Catalog.Dialogue.QuestVersion,
      records: processed_records,
      conflict_keys: [:id]
    }
  end
end
