defmodule Resdayn.Codex.Characters.ServicesOffered do
  use Ash.Type.Enum,
    values: [
      training: [label: "Training"],
      spellmaking: [label: "Spellmaking"],
      enchanting: [label: "Enchanting"],
      repairing: [label: "Repair"]
    ]
end
