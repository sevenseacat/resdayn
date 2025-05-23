defmodule Resdayn.Importer.Record.AlchemyApparatus do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    data =
      records
      |> of_type(Resdayn.Parser.Record.AlchemyApparatus)
      |> Enum.map(fn record ->
        record.data
        |> Map.take([:id, :name, :weight, :value, :quality, :script_id])
        |> Map.put(:apparatus_type, record.data.type)
        |> Map.put(:nif_model_filename, record.data.nif_model)
        |> Map.put(:icon_filename, record.data.icon)
        |> with_flags(:flags, record.flags)
      end)

    %{
      resource: Resdayn.Codex.Items.AlchemyApparatus,
      data: data
    }
  end
end