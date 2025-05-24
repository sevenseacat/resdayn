defmodule Resdayn.Codex.Characters.BodyPart.Flag do
  use Ash.Type.Enum, values: [
    :female,
    :playable
  ]
end