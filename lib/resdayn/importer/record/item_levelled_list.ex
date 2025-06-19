defmodule Resdayn.Importer.Record.ItemLevelledList do
  use Resdayn.Importer.Record

  def process(records, opts) do
    records
    |> of_type(Resdayn.Parser.Record.ItemLevelledList)
    |> Enum.map(fn record ->
      record.data
      |> Map.take([:id, :chance_none, :script_id])
      |> Map.put(:for_each_item, get_in(record.data, [:flags, :for_each_item]) || false)
      |> Map.put(
        :from_all_lower_levels,
        get_in(record.data, [:flags, :from_all_lower_levels]) || false
      )
      |> with_flags(:flags, record.flags)
    end)
    |> separate_for_import(Resdayn.Codex.Items.ItemLevelledList, opts)
  end
end
