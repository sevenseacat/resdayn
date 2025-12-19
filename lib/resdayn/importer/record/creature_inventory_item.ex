defmodule Resdayn.Importer.Record.CreatureInventoryItem do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> of_type(Resdayn.Parser.Record.Creature)
      |> Enum.map(fn record ->
        inventory =
          Enum.map(record.data[:inventory] || [], fn object ->
            %{
              object_ref_id: object.id,
              count: object.count,
              restocking?: object.restocking
            }
          end)

        %{
          id: record.data.id,
          inventory: inventory
        }
      end)

    %{
      type: :bulk_relationship,
      parent_resource: Resdayn.Codex.World.Creature,
      related_resource: Resdayn.Codex.World.InventoryItem,
      parent_key: :holder_ref_id,
      id_field: :object_ref_id,
      relationship_key: :inventory,
      on_missing: :destroy,
      records: processed_records
    }
  end
end
