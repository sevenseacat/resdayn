defmodule Resdayn.Importer.Record.Weapon do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> of_type(Resdayn.Parser.Record.Weapon)
      |> Enum.map(fn record ->
        record.data
        |> with_flags(:weapon_flags, record.data.flags)
        |> with_flags(:flags, record.flags)
      end)

    %{
      type: :fast_bulk,
      resource: Resdayn.Codex.Items.Weapon,
      records: processed_records,
      conflict_keys: [:id]
    }
  end
end
