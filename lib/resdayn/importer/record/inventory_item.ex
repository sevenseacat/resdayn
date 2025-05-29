defmodule Resdayn.Importer.Record.InventoryItem do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    process_inventory_items(records, Resdayn.Parser.Record.NPC, Resdayn.Codex.World.NPC)
  end
end
