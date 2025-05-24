defmodule Resdayn.Importer.Record.MiscellaneousItem do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    data =
      records
      |> of_type(Resdayn.Parser.Record.MiscellaneousItem)
      |> Enum.map(fn record ->
        record.data
        |> Map.take([:id, :name, :value, :weight, :script_id])
        |> Map.put(:nif_model_filename, record.data.nif_model)
        |> Map.put(:icon_filename, record.data.icon_filename)
        |> with_flags(:flags, record.flags)
      end)

    %{
      resource: Resdayn.Codex.Items.MiscellaneousItem,
      data: data
    }
  end
end