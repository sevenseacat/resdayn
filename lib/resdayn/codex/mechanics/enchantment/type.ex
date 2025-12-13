defmodule Resdayn.Codex.Mechanics.Enchantment.Type do
  use Ash.Type.Enum,
    values: [
      cast_once: [label: "Cast Once"],
      cast_when_used: [label: "Cast When Used"],
      cast_on_strike: [label: "Cast on Strike"],
      constant_effect: [label: "Constant Effect"]
    ]
end
