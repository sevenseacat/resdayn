defmodule Resdayn.Codex.Mechanics.Spell.Range do
  use Ash.Type.Enum, values: [:self, :touch, :target]
end