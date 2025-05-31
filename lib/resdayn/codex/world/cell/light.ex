defmodule Resdayn.Codex.World.Cell.Light do
  use Ash.Type.NewType,
    subtype_of: :map,
    constraints: [
      fields: [
        ambient: [type: :color],
        sunlight: [type: :color],
        fog: [type: :color],
        fog_density: [type: :float]
      ]
    ]
end
