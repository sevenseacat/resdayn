defmodule Resdayn.Importer.Record.Enchantment do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    data =
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
      resource: Resdayn.Codex.Mechanics.Enchantment,
      data: data
    }
  end
end
