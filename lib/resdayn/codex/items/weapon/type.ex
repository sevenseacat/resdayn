defmodule Resdayn.Codex.Items.Weapon.Type do
  use Ash.Type.Enum,
    values: [
      short_blade: "Short Blade",
      long_blade_1_hand: "Long Blade (1 Hand)",
      long_blade_2_hand: "Long Blade (2 Hand)",
      blunt_1_hand: "Blunt Weapon (1 Hand)",
      blunt_2_hand_close: "Blunt Weapon (2 Hand, Close)",
      blunt_2_hand_wide: "Blunt Weapon (2 Hand, Wide)",
      spear: "Spear",
      axe_1_hand: "Axe (1 Hand)",
      axe_2_hand: "Axe (2 Hand)",
      bow: "Longbow",
      crossbow: "Crossbow",
      thrown: "Thrown Weapon",
      arrow: "Arrow",
      bolt: "Bolt"
    ]
end
