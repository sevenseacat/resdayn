defmodule Resdayn.Codex.Characters.ServicesOffered do
  use Ash.Type.Enum,
    values: [
      training: "Training",
      spellmaking: "Spellmaking",
      enchanting: "Enchanting",
      repairing: "Repair"
    ]
end
