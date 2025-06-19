defmodule Resdayn.Importer.Record.Cell do
  use Resdayn.Importer.Record

  def process(records, opts) do
    records
    |> of_type(Resdayn.Parser.Record.Cell)
    |> Enum.map(fn record ->
      # Interior cells have nonsense values
      grid_position = if record.data.flags.interior, do: nil, else: record.data.grid_position

      # The ID is the position if it exists
      id = if is_list(grid_position), do: Enum.join(grid_position, ","), else: record.data.name

      {id,
       record.data
       |> Map.take([:name, :region_id, :map_color, :light, :water_height])
       |> Map.put(:id, id)
       |> Map.put(:grid_position, grid_position)
       |> with_flags(:cell_flags, record.data.flags)
       |> with_flags(:flags, record.flags)}
    end)
    # Handle duplicates by keeping only the first cell for each ID
    |> Enum.uniq_by(fn {id, _cell_data} -> id end)
    |> Enum.map(fn {_id, cell_data} -> cell_data end)
    |> separate_for_import(Resdayn.Codex.World.Cell, opts)
  end
end
