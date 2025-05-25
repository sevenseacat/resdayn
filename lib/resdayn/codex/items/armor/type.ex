defmodule Resdayn.Codex.Items.Armor.Type do
  use Ash.Type.Enum,
    values: [
      :helmet,
      :cuirass,
      :left_pauldron,
      :right_pauldron,
      :greaves,
      :boots,
      :left_gauntlet,
      :right_gauntlet,
      :shield,
      :left_bracer,
      :right_bracer
    ]
end
