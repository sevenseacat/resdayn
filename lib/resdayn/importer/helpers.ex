defmodule Resdayn.Importer.Helpers do
  @cell_size 8192

  @doc """
  Convert exterior coordinates into cell IDs.

  Each cell in Morrowind is a #{@cell_size}x#{@cell_size} square.
  """
  def coordinates_to_cell_id(%{x: x, y: y}) do
    grid_x = floor_div(x, @cell_size)
    grid_y = floor_div(y, @cell_size)

    "#{grid_x},#{grid_y}"
  end

  defp floor_div(value, divisor) do
    (value / divisor) |> Float.floor() |> trunc()
  end
end
