defmodule Resdayn.Importer.Record.Book do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> of_type(Resdayn.Parser.Record.Book)
      |> Enum.map(fn record ->
        record.data
        |> Map.put(:scroll, record.data.flags.scroll)
        |> with_flags(:flags, record.flags)
      end)
      # Remove the one help-the-user no-name book in Tamriel_Data.esm
      |> Enum.filter(&Map.has_key?(&1, :name))

    %{
      type: :fast_bulk,
      resource: Resdayn.Codex.Items.Book,
      records: processed_records,
      conflict_keys: [:id]
    }
  end
end
