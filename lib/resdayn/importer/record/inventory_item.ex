defmodule Resdayn.Importer.Record.InventoryItem do
  use Resdayn.Importer.Record

  def process(records, opts) do
    item_registry = Keyword.get(opts, :item_registry)

    data =
      records
      |> of_type(Resdayn.Parser.Record.NPC)
      |> Enum.flat_map(fn record ->
        carried_objects = record.data[:carried_objects] || []
        npc_id = record.data[:id]

        if npc_id != "player" and not Enum.empty?(carried_objects) do
          Resdayn.Importer.ItemRegistry.convert_inventory_data(
            carried_objects,
            npc_id,
            :npc,
            item_registry
          )
        else
          []
        end
      end)

    %{resource: Resdayn.Codex.World.InventoryItem, create: data}
  end
end
