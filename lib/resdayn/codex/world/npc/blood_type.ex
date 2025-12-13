defmodule Resdayn.Codex.World.NPC.BloodType do
  use Ash.Type.Enum,
    values: [
      skeleton: [label: "Skeleton"],
      metal_sparks: [label: "Metal sparks"],
      default: [label: "Default"]
    ]
end
