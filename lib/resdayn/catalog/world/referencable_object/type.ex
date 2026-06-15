defmodule Resdayn.Catalog.World.ReferencableObject.Type do
  @types %{
    weapon: Resdayn.Catalog.Items.Weapon,
    armor: Resdayn.Catalog.Items.Armor,
    tool: Resdayn.Catalog.Items.Tool,
    clothing: Resdayn.Catalog.Items.Clothing,
    book: Resdayn.Catalog.Items.Book,
    potion: Resdayn.Catalog.Items.Potion,
    ingredient: Resdayn.Catalog.Items.Ingredient,
    alchemy_apparatus: Resdayn.Catalog.Items.AlchemyApparatus,
    miscellaneous_item: Resdayn.Catalog.Items.MiscellaneousItem,
    light: Resdayn.Catalog.Assets.Light,
    static_object: Resdayn.Catalog.Assets.StaticObject,
    sound: Resdayn.Catalog.Assets.Sound,
    sound_generator: Resdayn.Catalog.Assets.SoundGenerator,
    npc: Resdayn.Catalog.World.NPC,
    item_levelled_list: Resdayn.Catalog.Items.ItemLevelledList,
    creature_levelled_list: Resdayn.Catalog.World.CreatureLevelledList,
    container: Resdayn.Catalog.World.Container,
    creature: Resdayn.Catalog.World.Creature,
    activator: Resdayn.Catalog.World.Activator,
    door: Resdayn.Catalog.World.Door
  }

  use Ash.Type.Enum, values: Map.keys(@types)

  # Mapping from type atom to resource module
  def type_to_resource(type) do
    Map.fetch!(@types, type)
  end

  def resource_to_type(type) do
    Enum.find(@types, fn {_, name} -> name == type end)
    |> elem(0)
  end
end
