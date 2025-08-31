defmodule Resdayn.Codex.World.NPC.BloodType do
  use Ash.Type.Enum,
    values: [skeleton: "Skeleton", metal_sparks: "Metal sparks", default: "Default"]
end
