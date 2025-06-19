defmodule Resdayn.Codex.World.Cell.Light do
  use Ash.Type.NewType,
    subtype_of: :map,
    constraints: [
      fields: [
        ambient: [type: Resdayn.Codex.Types.Color],
        sunlight: [type: Resdayn.Codex.Types.Color],
        fog: [type: Resdayn.Codex.Types.Color],
        fog_density: [type: :float]
      ]
    ]
end
