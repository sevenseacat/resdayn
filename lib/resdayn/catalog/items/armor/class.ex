defmodule Resdayn.Catalog.Items.Armor.Class do
  use Ash.Type.Enum,
    values: [
      light: [label: "Light"],
      medium: [label: "Medium"],
      heavy: [label: "Heavy"]
    ]
end
