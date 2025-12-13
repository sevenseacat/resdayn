defmodule Resdayn.Codex.Items.Weapon.Type do
  use Ash.Type.Enum,
    values: [
      short_blade: [label: "Short Blade"],
      long_blade_1_hand: [label: "Long Blade (1 Hand)"],
      long_blade_2_hand: [label: "Long Blade (2 Hand)"],
      blunt_1_hand: [label: "Blunt Weapon (1 Hand)"],
      blunt_2_hand_close: [label: "Blunt Weapon (2 Hand, Close)"],
      blunt_2_hand_wide: [label: "Blunt Weapon (2 Hand, Wide)"],
      spear: [label: "Spear"],
      axe_1_hand: [label: "Axe (1 Hand)"],
      axe_2_hand: [label: "Axe (2 Hand)"],
      bow: [label: "Longbow"],
      crossbow: [label: "Crossbow"],
      thrown: [label: "Thrown Weapon"],
      arrow: [label: "Arrow"],
      bolt: [label: "Bolt"]
    ]
end
