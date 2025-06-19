defmodule Resdayn.Importer.Record.Container do
  use Resdayn.Importer.Record

  def process(records, opts) do
    records
    |> of_type(Resdayn.Parser.Record.Container)
    |> Enum.map(fn record ->
      record.data
      |> Map.take([:id, :name, :script_id, :nif_model_filename, :capacity])
      |> with_flags(:container_flags, record.data.flags)
      |> with_flags(:flags, record.flags)
    end)
    |> separate_for_import(Resdayn.Codex.World.Container, opts)
  end
end
