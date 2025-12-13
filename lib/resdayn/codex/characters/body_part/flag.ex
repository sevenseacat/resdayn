defmodule Resdayn.Codex.Characters.BodyPart.Flag do
  use Ash.Type.Enum,
    values: [
      female: [label: "Female"],
      playable: [label: "Playable"]
    ]
end
