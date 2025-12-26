defmodule Resdayn.Codex.Mechanics.AppliedMagicEffect.ParentType do
  use Ash.Type.Enum, values: [:spell, :potion, :enchantment]
end
