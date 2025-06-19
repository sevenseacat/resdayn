defmodule Resdayn.Importer.Record.Armor do
  use Resdayn.Importer.Record

  def process(records, opts) do
    records
    |> of_type(Resdayn.Parser.Record.Armor)
    |> Enum.map(fn record ->
      record.data
      |> with_flags(:flags, record.flags)
    end)
    |> separate_for_import(Resdayn.Codex.Items.Armor, opts)
  end
end
