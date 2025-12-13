defmodule Resdayn.Codex.Items.Clothing.Type do
  use Ash.Type.Enum,
    values: [
      pants: [label: "Pants"],
      shoes: [label: "Shoes"],
      shirt: [label: "Shirt"],
      belt: [label: "Belt"],
      robe: [label: "Robe"],
      right_glove: [label: "Right Glove"],
      left_glove: [label: "Left Glove"],
      skirt: [label: "Skirt"],
      ring: [label: "Ring"],
      amulet: [label: "Amulet"]
    ]
end
