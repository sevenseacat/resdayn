defmodule Resdayn.Importer.Record.Clothing do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> of_type(Resdayn.Parser.Record.Clothing)
      |> Enum.map(fn record ->
        record.data
        |> with_flags(:flags, record.flags)
      end)

    %{
      type: :fast_bulk,
      resource: Resdayn.Codex.Items.Clothing,
      records: processed_records,
      conflict_keys: [:id]
    }
  end
end
