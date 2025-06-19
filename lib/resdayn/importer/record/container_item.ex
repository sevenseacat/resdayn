defmodule Resdayn.Importer.Record.ContainerItem do
  use Resdayn.Importer.Record

  def process(records, opts) do
    process_inventory_items(
      records,
      Resdayn.Parser.Record.Container,
      Resdayn.Codex.World.Container,
      opts
    )
  end
end
