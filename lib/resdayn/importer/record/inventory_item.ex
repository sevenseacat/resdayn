defmodule Resdayn.Importer.Record.InventoryItem do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    records
    |> of_type(Resdayn.Parser.Record.NPC)
    |> Enum.reject(&(&1.data.id == "player"))
    |> Enum.map(fn record ->
      carried_objects =
        Enum.map(record.data[:carried_objects] || [], fn object ->
          %{
            object_ref_id: object.id,
            count: object.count,
            restocking?: object.restocking
          }
        end)

      record.data
      |> Map.take([:id])
      |> Map.put(:carried_objects, carried_objects)
    end)
    |> separate_for_import(Resdayn.Codex.World.NPC, action: :import_relationships)
  end
end
