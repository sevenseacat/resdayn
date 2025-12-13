defmodule Resdayn.Codex.Items.Armor.Type do
  use Ash.Type.Enum,
    values: [
      helmet: [label: "Helmet"],
      cuirass: [label: "Cuirass"],
      left_pauldron: [label: "Left Pauldron"],
      right_pauldron: [label: "Right Pauldron"],
      greaves: [label: "Greaves"],
      boots: [label: "Boots"],
      left_gauntlet: [label: "Left Gauntlet"],
      right_gauntlet: [label: "Right Gauntlet"],
      shield: [label: "Shield"],
      left_bracer: [label: "Left Bracer"],
      right_bracer: [label: "Right Bracer"]
    ]
end
