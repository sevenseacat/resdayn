defmodule Resdayn.Catalog.World.Container.Flag do
  use Ash.Type.Enum,
    values: [
      organic: [label: "Organic"],
      respawns: [label: "Respawns"]
    ]
end
