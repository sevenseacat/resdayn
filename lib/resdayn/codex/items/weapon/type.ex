defmodule Resdayn.Codex.Items.Weapon.Type do
  use Ash.Type.Enum,
    values: [
      :short_blade,
      :long_blade_1_hand,
      :long_blade_2_hand,
      :blunt_1_hand,
      :blunt_2_hand_close,
      :blunt_2_hand_wide,
      :spear,
      :axe_1_hand,
      :axe_2_hand,
      :bow,
      :crossbow,
      :thrown,
      :arrow,
      :bolt
    ]
end
