defmodule Resdayn.Importer.Record.MiscellaneousItem do
  use Resdayn.Importer.Record

  def process(records, opts) do
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
    |> separate_for_import(Resdayn.Codex.Items.MiscellaneousItem, opts)
  end
end
