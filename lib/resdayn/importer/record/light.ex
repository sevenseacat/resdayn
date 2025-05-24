defmodule Resdayn.Importer.Record.Light do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    data =
      records
      |> of_type(Resdayn.Parser.Record.Light)
      |> Enum.map(fn record ->
        light_flags =
          record.data.flags
          |> Enum.filter(fn {_key, value} -> value end)
          |> Enum.map(fn {key, _value} -> key end)

        record.data
        |> Map.take([:id, :name, :weight, :value, :time, :radius, :color, :script_id, :sound_id])
        |> Map.put(:nif_model_filename, record.data[:nif_model])
        |> Map.put(:icon_filename, Map.get(record.data, :icon))
        |> Map.put(:light_flags, light_flags)
        |> with_flags(:flags, record.flags)
      end)

    %{
      resource: Resdayn.Codex.Assets.Light,
      data: data
    }
  end
end
