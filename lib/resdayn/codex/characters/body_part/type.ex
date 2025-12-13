defmodule Resdayn.Codex.Characters.BodyPart.Type do
  use Ash.Type.Enum,
    values: [
      head: [label: "Head"],
      hair: [label: "Hair"],
      neck: [label: "Neck"],
      chest: [label: "Chest"],
      groin: [label: "Groin"],
      hand: [label: "Hand"],
      wrist: [label: "Wrist"],
      forearm: [label: "Forearm"],
      upper_arm: [label: "Upper Arm"],
      foot: [label: "Foot"],
      ankle: [label: "Ankle"],
      knee: [label: "Knee"],
      upper_leg: [label: "Upper Leg"],
      clavicle: [label: "Clavicle"],
      tail: [label: "Tail"]
    ]
end
