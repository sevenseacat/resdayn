defmodule Resdayn.Codex.Characters.BodyPart.EquipmentType do
  use Ash.Type.Enum,
    values: [
      skin: [label: "Skin"],
      clothing: [label: "Clothing"],
      armor: [label: "Armor"]
    ]
end
