defmodule Resdayn.Codex.World.TransportDestination do
  use Ash.Type.NewType,
    subtype_of: :map,
    constraints: [
      fields: [
        # TODO: This *should* be a reference to a real cell but not imported yet...
        cell_name: [type: :string],
        coordinates: [type: :coordinates]
      ]
    ]

  @impl true
  def cast_input(nil, _), do: {:ok, nil}
  def cast_input(val, _), do: {:ok, val}
end
