defmodule Resdayn.Importer.Record.Weapon do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    data =
      records
      |> of_type(Resdayn.Parser.Record.Weapon)
      |> Enum.map(fn record ->
        record.data
        |> with_flags(:weapon_flags, record.data.flags)
        |> with_flags(:flags, record.flags)
      end)

    %{
      resource: Resdayn.Codex.Items.Weapon,
      data: data
    }
  end
end
