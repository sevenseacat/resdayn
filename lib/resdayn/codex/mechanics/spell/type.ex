defmodule Resdayn.Codex.Mechanics.Spell.Type do
  use Ash.Type.Enum,
    values: [
      spell: "Spell",
      ability: "Ability",
      blight: "Blight",
      disease: "Disease",
      curse: "Curse",
      power: "Power"
    ]
end
