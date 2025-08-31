defmodule Resdayn.Codex.World.Creature.Type do
  use Ash.Type.Enum,
    values: [creature: "Creature", humanoid: "Humanoid", daedra: "Daedra", undead: "Undead"]
end
