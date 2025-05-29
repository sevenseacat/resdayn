defmodule Resdayn.Codex.World.Creature.Type do
  use Ash.Type.Enum, values: [:creature, :humanoid, :daedra, :undead]
end
