defmodule Resdayn.Importer.Record.StaticObject do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    records
    |> of_type(Resdayn.Parser.Record.Static)
    |> Enum.map(fn record ->
      record.data
      |> Map.take([:id, :nif_model_filename])
      |> with_flags(:flags, record.flags)
    end)
    |> separate_for_import(Resdayn.Codex.Assets.StaticObject)
  end
end
