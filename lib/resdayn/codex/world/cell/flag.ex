defmodule Resdayn.Codex.World.Cell.Flag do
  use Ash.Type.Enum, values: [:interior, :has_water, :sleeping_illegal, :behave_like_exterior]
end
