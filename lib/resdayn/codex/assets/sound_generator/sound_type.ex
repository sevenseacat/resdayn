defmodule Resdayn.Codex.Assets.SoundGenerator.SoundType do
  use Ash.Type.Enum,
    values: [
      left_foot: [label: "Left Foot"],
      right_foot: [label: "Right Foot"],
      swim_left: [label: "Swim Left"],
      swim_right: [label: "Swim Right"],
      moan: [label: "Moan"],
      roar: [label: "Roar"],
      scream: [label: "Scream"],
      land: [label: "Land"]
    ]
end
