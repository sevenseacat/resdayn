defmodule Resdayn.Codex.Characters.ItemsVendored do
  use Ash.Type.Enum,
    values: [
      weapons: "Weapons",
      armor: "Armor",
      clothing: "Clothing",
      books: "Books",
      ingredients: "Ingredients",
      picks: "Lockpicks",
      probes: "Probes",
      lights: "Lights",
      apparatus: "Alchemy apparatus",
      repair_items: "Repair items",
      misc: "Miscellaneous items",
      spells: "Spells",
      magic_items: "Magic items",
      potions: "Potions"
    ]
end
