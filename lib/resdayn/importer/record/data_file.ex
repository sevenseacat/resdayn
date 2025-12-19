defmodule Resdayn.Importer.Record.DataFile do
  use Resdayn.Importer.Record

  def process(records, opts) do
    filename = Keyword.fetch!(opts, :filename)
    [record] = of_type(records, Resdayn.Parser.Record.MainHeader)

    processed_records = [
      record.data.header
      |> Map.take([:version, :company, :description])
      |> Map.merge(%{
        id: filename,
        filename: filename,
        master: record.data.header.flags.master,
        dependencies: Enum.reverse(record.data[:dependencies] || [])
      })
      |> with_flags(:flags, record.flags)
    ]

    %{
      type: :fast_bulk,
      resource: Resdayn.Codex.Mechanics.DataFile,
      records: processed_records,
      conflict_keys: [:id]
    }
  end
end
