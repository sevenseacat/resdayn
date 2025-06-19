defmodule Resdayn.Importer.Record.Enchantment do
  use Resdayn.Importer.Record

  def process(records, opts) do
    records
    |> of_type(Resdayn.Parser.Record.Enchantment)
    |> Enum.map(fn record ->
      record.data
      |> Map.take([:id, :type, :cost, :charge])
      |> Map.put(:autocalc, record.data.flags.autocalc)
      |> Map.put(:effects, Map.get(record.data, :enchantments, []))
      |> with_flags(:flags, record.flags)
    end)
    |> separate_for_import(Resdayn.Codex.Mechanics.Enchantment, opts)
  end
end
