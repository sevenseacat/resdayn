defmodule Resdayn.Codex.Assets.SoundGenerator.SoundType do
  use Ash.Type.Enum,
    values: [
      left_foot: "Left Foot",
      right_foot: "Right Foot",
      swim_left: "Swim Left",
      swim_right: "Swim Right",
      moan: "Moan",
      roar: "Roar",
      scream: "Scream",
      land: "Land"
    ]
end
