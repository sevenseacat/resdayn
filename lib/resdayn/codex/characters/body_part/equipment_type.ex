defmodule Resdayn.Codex.Characters.BodyPart.EquipmentType do
  use Ash.Type.Enum,
    values: [
      skin: "Skin",
      clothing: "Clothing",
      armor: "Armor"
    ]
end
