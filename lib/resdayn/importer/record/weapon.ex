defmodule Resdayn.Importer.Record.Weapon do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    records
    |> of_type(Resdayn.Parser.Record.Weapon)
    |> Enum.map(fn record ->
      record.data
      |> with_flags(:weapon_flags, record.data.flags)
      |> with_flags(:flags, record.flags)
    end)
    |> separate_for_import(Resdayn.Codex.Items.Weapon)
  end
end
