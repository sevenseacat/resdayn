defmodule Resdayn.Catalog.Calculations.TypedObject do
  use Ash.Resource.Calculation
  require Ash.Query

  @impl true
  def strict_loads?, do: false

  @impl true
  def load(_query, opts, _context) do
    if opts[:field] do
      [opts[:field]]
    else
      [opts[:type_field], opts[:id_field]]
    end
  end

  @impl true
  def calculate(records, opts, _context) do
    {get_type, get_id} = accessors(opts)

    # Group by object type for efficient batch loading
    typed_objects =
      records
      |> Enum.group_by(get_type)
      |> Enum.flat_map(fn {type, entries} ->
        object_ids = Enum.map(entries, get_id)
        resource = Resdayn.Catalog.World.ReferencableObject.Type.type_to_resource(type)

        resource
        |> Ash.Query.for_read(:read)
        |> Ash.Query.filter(id in ^object_ids)
        |> Ash.read!()
        |> Enum.map(&{to_string(&1.id), &1})
      end)
      |> Map.new()

    # Return in same order as input records
    Enum.map(records, fn record ->
      Map.get(typed_objects, to_string(get_id.(record)))
    end)
  end

  defp accessors(opts) do
    if opts[:field] do
      # Single field pointing to a struct with .type and .id (e.g. ReferencableObject)
      field = opts[:field]

      {
        fn record -> Map.fetch!(record, field).type end,
        fn record -> Map.fetch!(record, field).id end
      }
    else
      # Separate type and id fields (e.g. Override with resource_type + record_id)
      type_field = Keyword.fetch!(opts, :type_field)
      id_field = Keyword.fetch!(opts, :id_field)

      {
        fn record -> Map.fetch!(record, type_field) end,
        fn record -> Map.fetch!(record, id_field) end
      }
    end
  end
end
