defmodule Resdayn.Importer.Record.GlobalVariable do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> of_type(Resdayn.Parser.Record.GlobalVariable)
      |> Enum.map(fn record ->
        record.data
        |> Map.take([:id, :value])
        |> with_flags(:flags, record.flags)
      end)

    %{
      type: :fast_bulk,
      resource: Resdayn.Codex.Mechanics.GlobalVariable,
      records: processed_records,
      conflict_keys: [:id]
    }
  end
end
