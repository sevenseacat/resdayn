defmodule Resdayn.Codex.World.NPC.Flag do
  use Ash.Type.Enum,
    values: [
      female: [label: "Female"],
      respawn: [label: "Respawns"],
      essential: [label: "Essential"],
      autocalc: [label: "Auto-calculated Stats"]
    ]
end
