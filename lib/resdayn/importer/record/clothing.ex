defmodule Resdayn.Importer.Record.Clothing do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    data =
      records
      |> of_type(Resdayn.Parser.Record.Clothing)
      |> Enum.map(fn record ->
        record.data
        |> with_flags(:flags, record.flags)
      end)

    %{
      resource: Resdayn.Codex.Items.Clothing,
      data: data
    }
  end
end
