defmodule Resdayn.Codex.World.Creature.Flag do
  use Ash.Type.Enum,
    values: [
      biped: [label: "Bipedal"],
      respawn: [label: "Respawns"],
      weapon_and_shield: [label: "Uses a weapon and shield"],
      none: [label: "N/A"],
      swims: [label: "Swims"],
      flies: [label: "Flies"],
      walks: [label: "Walks"],
      default: [label: "Default"],
      essential: [label: "Essential"],
      blood_type_1: [label: "Blood Type 1"],
      blood_type_2: [label: "Blood Type 2"],
      blood_type_3: [label: "Blood Type 3"],
      blood_type_4: [label: "Blood Type 4"],
      blood_type_5: [label: "Blood Type 5"],
      blood_type_6: [label: "Blood Type 6"],
      blood_type_7: [label: "Blood Type 7"]
    ]
end
