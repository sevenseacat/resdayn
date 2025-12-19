defmodule Resdayn.Importer.Record.Light do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> of_type(Resdayn.Parser.Record.Light)
      |> Enum.map(fn record ->
        record.data
        |> Map.take([
          :id,
          :name,
          :weight,
          :value,
          :time,
          :radius,
          :color,
          :script_id,
          :sound_id,
          :nif_model_filename,
          :icon_filename
        ])
        |> with_flags(:light_flags, record.data.flags)
        |> with_flags(:flags, record.flags)
      end)

    %{
      type: :fast_bulk,
      resource: Resdayn.Codex.Assets.Light,
      records: processed_records,
      conflict_keys: [:id]
    }
  end
end
