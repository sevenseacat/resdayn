defmodule Resdayn.Codex.World.NPC.Flag do
  use Ash.Type.Enum,
    values: [
      female: "Female",
      respawn: "Respawns",
      essential: "Essential",
      autocalc: "Auto-calculated Stats"
    ]
end
