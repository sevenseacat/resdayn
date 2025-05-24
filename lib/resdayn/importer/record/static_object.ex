defmodule Resdayn.Importer.Record.StaticObject do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    data =
      records
      |> of_type(Resdayn.Parser.Record.Static)
      |> Enum.map(fn record ->
        record.data
        |> Map.take([:id])
        |> Map.put(:nif_model_filename, record.data.nif_model)
        |> with_flags(:flags, record.flags)
      end)

    %{
      resource: Resdayn.Codex.Assets.StaticObject,
      data: data
    }
  end
end