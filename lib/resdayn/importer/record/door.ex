defmodule Resdayn.Importer.Record.Door do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    data =
      records
      |> of_type(Resdayn.Parser.Record.Door)
      |> Enum.map(fn record ->
        record.data
        |> with_flags(:flags, record.flags)
      end)

    %{
      resource: Resdayn.Codex.World.Door,
      data: data
    }
  end
end
