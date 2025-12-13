defmodule Resdayn.Codex.World.Creature.Type do
  use Ash.Type.Enum,
    values: [
      creature: [label: "Creature"],
      humanoid: [label: "Humanoid"],
      daedra: [label: "Daedra"],
      undead: [label: "Undead"]
    ]
end
