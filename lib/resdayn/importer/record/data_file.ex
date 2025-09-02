defmodule Resdayn.Importer.Record.DataFile do
  use Resdayn.Importer.Record
  require Ash.Query

  @resource Resdayn.Codex.Mechanics.DataFile

  def process(records, opts) do
    filename = Keyword.fetch!(opts, :filename)
    [record] = of_type(records, Resdayn.Parser.Record.MainHeader)

    data =
      record.data.header
      |> Map.take([:version, :company, :description])
      |> Map.merge(%{
        id: filename,
        filename: filename,
        master: record.data.header.flags.master,
        dependencies: Enum.reverse(record.data[:dependencies] || [])
      })
      |> with_flags(:flags, record.flags)

    [data]
    |> separate_for_import(@resource, opts)
  end
end
