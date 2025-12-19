defmodule Resdayn.Importer.Record.StaticObject do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> of_type(Resdayn.Parser.Record.Static)
      |> Enum.map(fn record ->
        record.data
        |> Map.take([:id, :nif_model_filename])
        |> with_flags(:flags, record.flags)
      end)

    %{
      type: :fast_bulk,
      resource: Resdayn.Codex.Assets.StaticObject,
      records: processed_records,
      conflict_keys: [:id]
    }
  end
end
