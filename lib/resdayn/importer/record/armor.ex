defmodule Resdayn.Importer.Record.Armor do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    data =
      records
      |> of_type(Resdayn.Parser.Record.Armor)
      |> Enum.map(fn record ->
        record.data
        |> with_flags(:flags, record.flags)
      end)

    %{
      resource: Resdayn.Codex.Items.Armor,
      data: data
    }
  end
end
