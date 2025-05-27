defmodule Resdayn.Importer.Record.DataFile do
  use Resdayn.Importer.Record
  require Ash.Query

  @resource Resdayn.Codex.Mechanics.DataFile

  def process(records, opts) do
    filename = Keyword.fetch!(opts, :filename)
    [record] = of_type(records, Resdayn.Parser.Record.MainHeader)

    existing =
      Ash.Query.for_read(@resource, :read)
      |> Ash.Query.filter(filename == ^filename)
      |> Ash.read_one!()

    data =
      record.data.header
      |> Map.take([:version, :company, :description])
      |> Map.merge(%{
        filename: filename,
        master: record.data.header.flags.master,
        dependencies: Enum.reverse(record.data[:dependencies] || [])
      })
      |> with_flags(:flags, record.flags)

    if existing do
      %{resource: @resource, update: [Ash.Changeset.for_update(existing, :import_update, data)]}
    else
      %{resource: @resource, create: [data]}
    end
  end
end
