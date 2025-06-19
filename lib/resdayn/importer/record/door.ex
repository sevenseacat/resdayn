defmodule Resdayn.Importer.Record.Door do
  use Resdayn.Importer.Record

  def process(records, opts) do
    records
    |> of_type(Resdayn.Parser.Record.Door)
    |> Enum.map(fn record ->
      record.data
      |> with_flags(:flags, record.flags)
    end)
    |> separate_for_import(Resdayn.Codex.World.Door, opts)
  end
end
