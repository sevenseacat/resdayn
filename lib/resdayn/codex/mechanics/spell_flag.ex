defmodule Resdayn.Codex.Mechanics.SpellFlag do
  use Ash.Type.Enum,
    values: [
      autocalc: [label: "Auto-calculated stats"],
      starting_spell: [label: "Starting spell"],
      always_succeeds: [label: "Always succeeds"]
    ]
end
