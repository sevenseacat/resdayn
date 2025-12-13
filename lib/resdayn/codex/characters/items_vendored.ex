defmodule Resdayn.Codex.Characters.ItemsVendored do
  use Ash.Type.Enum,
    values: [
      weapons: [label: "Weapons"],
      armor: [label: "Armor"],
      clothing: [label: "Clothing"],
      books: [label: "Books"],
      ingredients: [label: "Ingredients"],
      picks: [label: "Lockpicks"],
      probes: [label: "Probes"],
      lights: [label: "Lights"],
      apparatus: [label: "Alchemy apparatus"],
      repair_items: [label: "Repair items"],
      misc: [label: "Miscellaneous items"],
      spells: [label: "Spells"],
      magic_items: [label: "Magic items"],
      potions: [label: "Potions"]
    ]
end
