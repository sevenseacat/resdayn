defmodule Resdayn.Codex.Calculations.TypedObject do
  use Ash.Resource.Calculation
  require Ash.Query

  @impl true
  def strict_loads?, do: false

  @impl true
  def load(_query, [field: field], _context), do: [field]

  @impl true
  def calculate(records, opts, _context) do
    field = Keyword.fetch!(opts, :field)
    # Group by object type for efficient batch loading
    by_type = Enum.group_by(records, &Map.fetch!(&1, field).type)

    # Load each type in batch
    typed_objects =
      Enum.flat_map(by_type, fn {type, entries} ->
        object_ids = Enum.map(entries, &Map.fetch!(&1, field).id)
        resource = Resdayn.Codex.World.ReferencableObject.Type.type_to_resource(type)

        objects =
          resource
          |> Ash.Query.for_read(:read)
          |> Ash.Query.filter(id in ^object_ids)
          |> Ash.read!()

        Enum.map(objects, &{&1.id, &1})
      end)
      |> Map.new()

    # Return in same order as input records
    Enum.map(records, fn record ->
      Map.get(typed_objects, Map.fetch!(record, field).id)
    end)
  end
end
