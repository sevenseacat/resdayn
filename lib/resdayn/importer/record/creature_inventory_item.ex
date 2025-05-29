defmodule Resdayn.Importer.Record.CreatureInventoryItem do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    process_inventory_items(records, Resdayn.Parser.Record.Creature, Resdayn.Codex.World.Creature)
  end
end
