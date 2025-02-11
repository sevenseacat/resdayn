defmodule Resdayn.Importer.Record.GlobalVariable do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    data =
      records
      |> of_type(Resdayn.Parser.Record.GlobalVariable)
      |> Enum.map(fn record ->
        record.data
        |> Map.take([:id, :value])
        |> with_flags(:flags, record.flags)
      end)

    %{
      resource: Resdayn.Codex.Mechanics.GlobalVariable,
      data: data
    }
  end
end
