defmodule Resdayn.Importer.Record.Book do
  use Resdayn.Importer.Record

  def process(records, opts) do
    records
    |> of_type(Resdayn.Parser.Record.Book)
    |> Enum.map(fn record ->
      record.data
      |> Map.put(:scroll, record.data.flags.scroll)
      |> with_flags(:flags, record.flags)
    end)
    # Remove the one help-the-user no-name book in Tamriel_Data.esm
    |> Enum.filter(&Map.has_key?(&1, :name))
    |> separate_for_import(Resdayn.Codex.Items.Book, opts)
  end
end
