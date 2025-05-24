defmodule Resdayn.Codex.Mechanics.SpellFlag do
  use Ash.Type.Enum, values: [
    :autocalc,
    :starting_spell,
    :always_succeeds
  ]
end