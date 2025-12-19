defmodule Resdayn.Importer.Record.MiscellaneousItem do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> of_type(Resdayn.Parser.Record.MiscellaneousItem)
      |> Enum.map(fn record ->
        record.data
        |> Map.take([
          :id,
          :name,
          :value,
          :weight,
          :script_id,
          :icon_filename,
          :nif_model_filename
        ])
        |> with_flags(:flags, record.flags)
      end)
      # Ignore one dodgy MiscellaneousItem in Tribunal.esm with no `name`/`icon_filename`
      |> Enum.reject(&(!Map.get(&1, :name)))

    %{
      type: :fast_bulk,
      resource: Resdayn.Codex.Items.MiscellaneousItem,
      records: processed_records,
      conflict_keys: [:id]
    }
  end
end
