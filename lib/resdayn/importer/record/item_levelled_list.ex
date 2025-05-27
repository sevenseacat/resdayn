defmodule Resdayn.Importer.Record.ItemLevelledList do
  use Resdayn.Importer.Record

  def process(records, opts) do
    item_registry = Keyword.fetch!(opts, :item_registry)

    records
    |> of_type(Resdayn.Parser.Record.ItemLevelledList)
    |> Enum.map(fn record ->
      # Process items list with type resolution
      items =
        (record.data[:items] || [])
        |> Enum.map(fn item ->
          item_type = Resdayn.Importer.ItemRegistry.lookup_item_type(item_registry, item.id)

          final_item_type =
            if is_nil(item_type) do
              :item_levelled_list
            else
              item_type
            end

          %{
            item_id: item.id,
            item_type: final_item_type,
            player_level: item.player_level
          }
        end)

      record.data
      |> Map.take([:id, :chance_none, :script_id])
      |> Map.put(:for_each_item, get_in(record.data, [:flags, :for_each_item]) || false)
      |> Map.put(
        :from_all_lower_levels,
        get_in(record.data, [:flags, :from_all_lower_levels]) || false
      )
      |> Map.put(:items, items)
      |> with_flags(:flags, record.flags)
    end)
    |> separate_for_import(Resdayn.Codex.Items.ItemLevelledList)
  end
end
