defmodule Resdayn.Importer.Record.MiscellaneousItem do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    data =
      records
      |> of_type(Resdayn.Parser.Record.MiscellaneousItem)
      |> Enum.map(fn record ->
        record.data
        |> Map.take([:id, :name, :value, :weight, :script_id, :icon_filename])
        |> Map.put(:nif_model_filename, record.data.nif_model)
        |> with_flags(:flags, record.flags)
      end)
      # Ignore one dodgy MiscellaneousItem in Tribunal.esm with no `name`/`icon_filename`
      |> Enum.reject(&(!Map.get(&1, :name)))

    %{
      resource: Resdayn.Codex.Items.MiscellaneousItem,
      data: data
    }
  end
end
