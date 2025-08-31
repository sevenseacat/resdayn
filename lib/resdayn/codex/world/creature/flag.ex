defmodule Resdayn.Codex.World.Creature.Flag do
  use Ash.Type.Enum,
    values: [
      biped: "Bipedal",
      respawn: "Respawns",
      weapon_and_shield: "Uses a weapon and shield",
      none: "N/A",
      swims: "Swims",
      flies: "Flies",
      walks: "Walks",
      default: "Default",
      essential: "Essential",
      blood_type_1: "Blood Type 1",
      blood_type_2: "Blood Type 2",
      blood_type_3: "Blood Type 3",
      blood_type_4: "Blood Type 4",
      blood_type_5: "Blood Type 5",
      blood_type_6: "Blood Type 6",
      blood_type_7: "Blood Type 7"
    ]
end
