defmodule Resdayn.Codex.World.Creature.Flag do
  use Ash.Type.Enum,
    values: [
      :biped,
      :respawn,
      :weapon_and_shield,
      :none,
      :swims,
      :flies,
      :walks,
      :default,
      :essential,
      :blood_type_1,
      :blood_type_2,
      :blood_type_3,
      :blood_type_4,
      :blood_type_5,
      :blood_type_6,
      :blood_type_7
    ]
end
