defmodule Resdayn.Importer.Record.Potion do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    data =
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
      resource: Resdayn.Codex.Items.Potion,
      data: data
    }
  end
end
