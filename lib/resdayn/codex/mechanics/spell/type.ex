defmodule Resdayn.Codex.Mechanics.Spell.Type do
  use Ash.Type.Enum,
    values: [
      spell: [label: "Spell"],
      ability: [label: "Ability"],
      blight: [label: "Blight"],
      disease: [label: "Disease"],
      curse: [label: "Curse"],
      power: [label: "Power"]
    ]
end
