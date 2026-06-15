defmodule Resdayn.Importer.Record.AlchemyApparatus do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> of_type(Resdayn.Parser.Record.AlchemyApparatus)
      |> Enum.map(fn record ->
        record.data
        |> Map.take([
          :id,
          :name,
          :type,
          :weight,
          :value,
          :quality,
          :script_id,
          :nif_model_filename,
          :icon_filename
        ])
        |> with_flags(:flags, record.flags)
      end)

    %{
      type: :record,
      resource: Resdayn.Catalog.Items.AlchemyApparatus,
      records: processed_records,
      conflict_keys: [:id]
    }
  end
end
