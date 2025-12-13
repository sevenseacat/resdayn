defmodule Resdayn.Codex.Characters.Specialization do
  use Ash.Type.Enum,
    values: [
      combat: [label: "Combat"],
      magic: [label: "Magic"],
      stealth: [label: "Stealth"]
    ]
end
