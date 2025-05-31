defmodule Resdayn.Codex.World.ReferencableObject.Type do
  @types %{
    weapon: Resdayn.Codex.Items.Weapon,
    armor: Resdayn.Codex.Items.Armor,
    tool: Resdayn.Codex.Items.Tool,
    clothing: Resdayn.Codex.Items.Clothing,
    book: Resdayn.Codex.Items.Book,
    potion: Resdayn.Codex.Items.Potion,
    ingredient: Resdayn.Codex.Items.Ingredient,
    alchemy_apparatus: Resdayn.Codex.Items.AlchemyApparatus,
    miscellaneous_item: Resdayn.Codex.Items.MiscellaneousItem,
    light: Resdayn.Codex.Assets.Light,
    static_object: Resdayn.Codex.Assets.StaticObject,
    sound: Resdayn.Codex.Assets.Sound,
    sound_generator: Resdayn.Codex.Assets.SoundGenerator,
    npc: Resdayn.Codex.World.NPC,
    item_levelled_list: Resdayn.Codex.Items.ItemLevelledList,
    creature_levelled_list: Resdayn.Codex.World.CreatureLevelledList,
    container: Resdayn.Codex.World.Container,
    creature: Resdayn.Codex.World.Creature,
    activator: Resdayn.Codex.World.Activator,
    door: Resdayn.Codex.World.Door
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
