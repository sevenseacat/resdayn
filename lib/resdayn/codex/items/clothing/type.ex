defmodule Resdayn.Codex.Items.Clothing.Type do
  use Ash.Type.Enum,
    values: [
      pants: "Pants",
      shoes: "Shoes",
      shirt: "Shirt",
      belt: "Belt",
      robe: "Robe",
      right_glove: "Right Glove",
      left_glove: "Left Glove",
      skirt: "Skirt",
      ring: "Ring",
      amulet: "Amulet"
    ]
end
