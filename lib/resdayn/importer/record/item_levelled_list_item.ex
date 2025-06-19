defmodule Resdayn.Importer.Record.ItemLevelledListItem do
  use Resdayn.Importer.Record

  def process(records, opts) do
    records
    |> of_type(Resdayn.Parser.Record.ItemLevelledList)
    |> Enum.map(fn record ->
      # Process items list with type resolution
      items =
        (record.data[:items] || [])
        |> Enum.map(fn item ->
          %{
            item_ref_id: item.id,
            player_level: item.player_level
          }
        end)

      record.data
      |> Map.take([:id])
      |> Map.put(:items, items)
    end)
    |> separate_for_import(Resdayn.Codex.Items.ItemLevelledList, opts)
  end
end
