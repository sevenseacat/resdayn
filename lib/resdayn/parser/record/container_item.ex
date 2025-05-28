defmodule Resdayn.Importer.Record.ContainerItem do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    records
    |> of_type(Resdayn.Parser.Record.Container)
    |> Enum.map(fn record ->
      inventory =
        Enum.map(record.data[:inventory] || [], fn object ->
          %{
            object_ref_id: object.id,
            count: object.count,
            restocking?: object.restocking
          }
        end)

      record.data
      |> Map.take([:id])
      |> Map.put(:inventory, inventory)
    end)
    |> separate_for_import(Resdayn.Codex.World.Container, action: :import_relationships)
  end
end
