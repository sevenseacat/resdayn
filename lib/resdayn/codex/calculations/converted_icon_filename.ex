defmodule Resdayn.Codex.Calculations.ConvertedIconFilename do
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context) do
    [template: [:icon_filename]]
  end

  @impl true
  def calculate(records, _opts, _context) do
    Enum.map(records, fn record ->
      filename =
        record.template.icon_filename
        |> String.replace("s\\", "b_")
        |> String.replace(".tga", ".png")
        |> String.downcase()

      Path.join("/images/magic_effects/", filename)
    end)
  end
end
