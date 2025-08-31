defmodule Resdayn.Codex.Mechanics.Enchantment.Type do
  use Ash.Type.Enum,
    values: [
      cast_once: "Cast Once",
      cast_when_used: "Cast When Used",
      cast_on_strike: "Cast on Strike",
      constant_effect: "Constant Effect"
    ]
end
