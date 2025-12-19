defmodule Resdayn.Importer.Record.Enchantment do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> of_type(Resdayn.Parser.Record.Enchantment)
      |> Enum.map(fn record ->
        record.data
        |> Map.take([:id, :type, :cost, :charge])
        |> Map.put(:autocalc, record.data.flags.autocalc)
        |> Map.put(:effects, Map.get(record.data, :enchantments, []))
        |> with_flags(:flags, record.flags)
      end)

    %{
      type: :fast_bulk,
      resource: Resdayn.Codex.Mechanics.Enchantment,
      records: processed_records,
      conflict_keys: [:id]
    }
  end
end
