defmodule Resdayn.Importer.Record.Clothing do
  use Resdayn.Importer.Record

  def process(records, opts) do
    records
    |> of_type(Resdayn.Parser.Record.Clothing)
    |> Enum.map(fn record ->
      record.data
      |> with_flags(:flags, record.flags)
    end)
    |> separate_for_import(Resdayn.Codex.Items.Clothing, opts)
  end
end
