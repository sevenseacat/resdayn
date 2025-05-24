defmodule Resdayn.Codex.Characters.BodyPart.EquipmentType do
  use Ash.Type.Enum, values: [
    :skin,
    :clothing,
    :armour
  ]
end