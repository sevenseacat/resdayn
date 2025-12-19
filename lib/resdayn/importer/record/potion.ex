defmodule Resdayn.Importer.Record.Potion do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> of_type(Resdayn.Parser.Record.Potion)
      |> Enum.map(fn record ->
        record.data
        |> Map.take([
          :id,
          :name,
          :weight,
          :value,
          :script_id,
          :effects,
          :nif_model_filename,
          :icon_filename
        ])
        |> Map.put(:autocalc, record.data.flags.autocalc)
        |> with_flags(:flags, record.flags)
      end)

    %{
      type: :fast_bulk,
      resource: Resdayn.Codex.Items.Potion,
      records: processed_records,
      conflict_keys: [:id]
    }
  end
end
