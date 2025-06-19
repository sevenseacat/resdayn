defmodule Resdayn.Importer.Record.CreatureInventoryItem do
  use Resdayn.Importer.Record

  def process(records, opts) do
    process_inventory_items(
      records,
      Resdayn.Parser.Record.Creature,
      Resdayn.Codex.World.Creature,
      opts
    )
  end
end
