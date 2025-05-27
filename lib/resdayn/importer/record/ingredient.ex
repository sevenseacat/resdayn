defmodule Resdayn.Importer.Record.Ingredient do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    records
    |> of_type(Resdayn.Parser.Record.Ingredient)
    |> Enum.map(fn record ->
      record.data
      |> with_flags(:flags, record.flags)
    end)
    |> separate_for_import(Resdayn.Codex.Items.Ingredient)
  end
end
