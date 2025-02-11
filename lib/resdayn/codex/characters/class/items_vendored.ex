defmodule Resdayn.Codex.Characters.Class.ItemsVendored do
  use Ash.Type.Enum,
    values: [
      :weapons,
      :armor,
      :clothing,
      :books,
      :ingredients,
      :picks,
      :probes,
      :lights,
      :apparatus,
      :repair_items,
      :misc,
      :spells,
      :magic_items,
      :potions
    ]
end
