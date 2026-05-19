defmodule Resdayn.Importer.Record.Quest do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    index = Resdayn.Importer.FactionResolver.build_index()

    processed_records =
      records
      |> chunked_dialogues(:journal)
      |> Enum.map(fn {topic, entries} ->
        # Only emit :name and :faction_id when this pass has a QSTN-flagged INFO
        # (the "quest name" entry). Override records without QSTN — TR_Mainland
        # tweaks to vanilla quests, T_Rules_* infrastructure records — fall
        # through with just :id, which preserves any existing name/faction set
        # by an earlier pass and lets source_file_ids accumulate.
        case Enum.find(entries, fn resp -> resp.data[:quest_name] end) do
          nil ->
            %{id: topic.data.id}

          name_response ->
            {faction_id, quest_name} =
              Resdayn.Importer.FactionResolver.resolve(name_response.data.content, index)

            %{
              id: topic.data.id,
              name: quest_name,
              faction_id: faction_id
            }
        end
      end)

    %{
      type: :record,
      resource: Resdayn.Codex.Dialogue.Quest,
      records: processed_records,
      conflict_keys: [:id]
    }
  end
end
