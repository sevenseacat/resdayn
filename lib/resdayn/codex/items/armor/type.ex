defmodule Resdayn.Codex.Items.Armor.Type do
  use Ash.Type.Enum,
    values: [
      helmet: "Helmet",
      cuirass: "Cuirass",
      left_pauldron: "Left Pauldron",
      right_pauldron: "Right Pauldron",
      greaves: "Greaves",
      boots: "Boots",
      left_gauntlet: "Left Gauntlet",
      right_gauntlet: "Right Gauntlet",
      shield: "Shield",
      left_bracer: "Left Bracer",
      right_bracer: "Right Bracer"
    ]
end
