defmodule Resdayn.Codex.Characters.Specialization do
  use Ash.Type.Enum, values: [combat: "Combat", magic: "Magic", stealth: "Stealth"]
end
