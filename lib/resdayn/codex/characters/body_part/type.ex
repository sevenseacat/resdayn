defmodule Resdayn.Codex.Characters.BodyPart.Type do
  use Ash.Type.Enum,
    values: [
      head: "Head",
      hair: "Hair",
      neck: "Neck",
      chest: "Chest",
      groin: "Groin",
      hand: "Hand",
      wrist: "Wrist",
      forearm: "Forearm",
      upper_arm: "Upper Arm",
      foot: "Foot",
      ankle: "Ankle",
      knee: "Knee",
      upper_leg: "Upper Leg",
      clavicle: "Clavicle",
      tail: "Tail"
    ]
end
