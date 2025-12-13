defmodule Resdayn.Codex.Items.Weapon.Flag do
  use Ash.Type.Enum,
    values: [
      ignore_resistance: [label: "Ignores resistance"],
      silver: [label: "Silver"]
    ]
end
