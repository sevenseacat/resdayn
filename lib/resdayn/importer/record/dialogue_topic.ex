defmodule Resdayn.Importer.Record.DialogueTopic do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> chunked_dialogues()
      |> Enum.map(fn {record, _} ->
        record.data
        |> with_flags(:flags, record.flags)
      end)

    %{
      type: :fast_bulk,
      resource: Resdayn.Codex.Dialogue.Topic,
      records: processed_records,
      conflict_keys: [:id]
    }
  end
end
