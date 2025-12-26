defmodule Resdayn.Importer.Record.Spell do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> of_type(Resdayn.Parser.Record.Spell)
      |> Enum.map(fn record ->
        record.data
        |> Map.take([:id, :name, :type, :cost])
        |> with_flags(:flags, record.flags)
        |> with_flags(:spell_flags, record.data.flags)
      end)
      |> Enum.uniq_by(fn spell_data -> spell_data.id end)

    %{
      type: :fast_bulk,
      resource: Resdayn.Codex.Mechanics.Spell,
      records: processed_records,
      conflict_keys: [:id]
    }
  end
end
