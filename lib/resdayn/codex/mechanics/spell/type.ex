defmodule Resdayn.Codex.Mechanics.Spell.Type do
  use Ash.Type.Enum, values: [:spell, :ability, :blight, :disease, :curse, :power]
end
