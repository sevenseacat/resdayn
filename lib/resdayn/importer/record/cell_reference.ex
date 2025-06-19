defmodule Resdayn.Importer.Record.CellReference do
  use Resdayn.Importer.Record

  def process(records, opts) do
    # TR has a lot of dodgy body parts and other non-referencable things as references for some reason?
    referencable =
      Ash.read!(Resdayn.Codex.World.ReferencableObject)
      |> Enum.map(& &1.id)
      |> MapSet.new()

    records
    |> of_type(Resdayn.Parser.Record.Cell)
    |> Enum.map(fn record ->
      # Interior cells have nonsense values
      grid_position = if record.data.flags.interior, do: nil, else: record.data.grid_position

      # The ID is the position if it exists
      cell_id =
        if is_list(grid_position), do: Enum.join(grid_position, ","), else: record.data.name

      # dodgy_refs =
      #   (record.data[:references] || [])
      #   |> Enum.reject(&(&1.reference_id in referencable))

      # if Enum.any?(dodgy_refs) do
      #   unique_ids =
      #     dodgy_refs
      #     |> Enum.map(& &1.reference_id)
      #     |> Enum.uniq()

      #   IO.puts(
      #     "#{length(dodgy_refs)} dodgy reference(s) cleaned from #{cell_id}: #{inspect(unique_ids)}"
      #   )
      # end

      references =
        (record.data[:references] || [])
        |> Enum.reject(&(&1.reference_id == "T_Aid_NPC" || &1.reference_id not in referencable))
        |> Enum.map(fn reference ->
          transport =
            if Map.has_key?(reference, :cell_travel) do
              %{
                cell_name: Map.get(reference, :cell_travel_name),
                coordinates: reference.cell_travel
              }
            else
              nil
            end

          usage =
            case Map.get(reference, :usage_remaining) do
              nil -> nil
              usage -> if usage.as_float, do: usage.as_float, else: usage.as_int
            end

          fields = [
            :id,
            :count,
            :scale,
            :coordinates,
            :lock_difficulty,
            :required_faction_rank,
            :enchantment_charge,
            :blocked,
            :reference_id,
            :owner_id,
            :owner_faction_id,
            :key_id,
            :trap_id,
            :soul_id,
            :global_variable_id
          ]

          fields
          |> Map.from_keys(nil)
          |> Map.merge(Map.take(reference, fields))
          # Some stuff is owned by the player in TR?
          |> Map.update(:owner_id, nil, fn o -> if o == "player", do: nil, else: o end)
          |> Map.put(:usage_remaining, usage)
          |> Map.put(:transport_to, transport)
        end)

      deleted =
        record.data
        |> Map.get(:deleted, [])
        |> Enum.map(fn %{id: {_index, ref_id}} -> %{id: ref_id, cell_id: cell_id} end)

      %{id: cell_id, new_references: references, deleted_references: deleted}
    end)
    |> separate_for_import(
      Resdayn.Codex.World.Cell,
      Keyword.put(opts, :action, :import_relationships)
    )
  end
end
