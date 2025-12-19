defmodule Resdayn.Importer.Record.ItemLevelledList do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> of_type(Resdayn.Parser.Record.ItemLevelledList)
      |> Enum.map(fn record ->
        # Transform items to use item_ref_id instead of id
        items =
          (record.data[:items] || [])
          |> Enum.map(fn item ->
            %{
              item_ref_id: item.id,
              player_level: item.player_level
            }
          end)

        record.data
        |> Map.take([:id, :chance_none, :script_id])
        |> Map.put(:items, items)
        |> Map.put(:for_each_item, get_in(record.data, [:flags, :for_each_item]) || false)
        |> Map.put(
          :from_all_lower_levels,
          get_in(record.data, [:flags, :from_all_lower_levels]) || false
        )
        |> with_flags(:flags, record.flags)
      end)

    %{
      type: :fast_bulk,
      resource: Resdayn.Codex.Items.ItemLevelledList,
      records: processed_records,
      conflict_keys: [:id]
    }
  end
end
