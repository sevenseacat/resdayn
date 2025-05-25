defmodule Resdayn.Codex.Items.Clothing.Type do
  use Ash.Type.Enum,
    values: [
      :pants,
      :shoes,
      :shirt,
      :belt,
      :robe,
      :right_glove,
      :left_glove,
      :skirt,
      :ring,
      :amulet
    ]
end
