defmodule Resdayn.Catalog.World.Cell.Light do
  use Ash.Type.NewType,
    subtype_of: :map,
    constraints: [
      fields: [
        ambient: [type: Resdayn.Catalog.Types.Color],
        sunlight: [type: Resdayn.Catalog.Types.Color],
        fog: [type: Resdayn.Catalog.Types.Color],
        fog_density: [type: :float]
      ]
    ]
end
