defmodule Resdayn.Importer.Record.DataFile do
  use Resdayn.Importer.Record

  def process(records, opts) do
    with [header] <- of_type(records, Resdayn.Parser.Record.MainHeader) do
      %{
        resource: Resdayn.Codex.Mechanics.DataFile,
        data: [
          header.data.header
          |> Map.take([:version, :company, :description])
          |> Map.merge(%{
            filename: Keyword.fetch!(opts, :filename),
            master: header.data.header.flags.master,
            dependencies: Enum.reverse(header.data[:dependencies] || [])
          })
          |> with_flags(:flags, header.flags)
        ]
      }
    else
      [] -> raise RuntimeError, "No main header found in file"
    end
  end
end
