defmodule Resdayn.Codex.Mechanics.SpellFlag do
  use Ash.Type.Enum,
    values: [
      autocalc: "Auto-calculated stats",
      starting_spell: "Starting spell",
      always_succeeds: "Always succeeds"
    ]
end
