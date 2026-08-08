defmodule Resdayn.Catalog.World.ReferencableObject.Type do
  @moduledoc """
  The kinds of object a reference can point at, and which of them each reference
  site will accept.

  The game engine type-checks references — the console refuses to put a container
  in your inventory. Nothing in this schema enforced that, so `allowed/1`
  reconstructs those rules from the shipped data.

  The sets are unions of three base kinds, plus at most the levelled list that
  resolves to the same kind. The one irregularity is that an item levelled list
  cannot be placed in a cell even though items can — it has no container to
  resolve into.

  > #### `static_object` is allowed on faith {: .warning}
  >
  > Statics are deliberately not imported (like land textures and path grids), so
  > no cell reference in the database points at one. That absence is an import gap,
  > not a game rule — the CS places statics in cells constantly. It stays in
  > `:cell_reference` so that enabling the STAT import later doesn't look like a
  > data bug.
  """

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
    npc: Resdayn.Catalog.World.NPC,
    item_levelled_list: Resdayn.Catalog.Items.ItemLevelledList,
    creature_levelled_list: Resdayn.Catalog.World.CreatureLevelledList,
    container: Resdayn.Catalog.World.Container,
    creature: Resdayn.Catalog.World.Creature,
    activator: Resdayn.Catalog.World.Activator,
    door: Resdayn.Catalog.World.Door
  }

  use Ash.Type.Enum, values: Map.keys(@types)

  # Anything a character can carry. Lights are here rather than with the scenery
  # because LIGH covers torches as well as fixtures, and torches go in inventories.
  @item ~w(alchemy_apparatus armor book clothing ingredient light
           miscellaneous_item potion tool weapon)a
  @actor ~w(creature npc)a
  @scenery ~w(activator container door static_object)a

  @sites %{
    cell_reference: @item ++ @actor ++ @scenery ++ [:creature_levelled_list],
    # Every one of the 2,051 keys in MW/TB/BM/TR is a misc item, but nothing is
    # known to enforce that — editors take these as free text, so a plugin can name
    # any item. Kept permissive so a legitimate one isn't rejected.
    cell_reference_key: @item,
    inventory_object: @item ++ [:item_levelled_list],
    inventory_holder: @actor ++ [:container],
    item_levelled_list_entry: @item ++ [:item_levelled_list],
    # NPCs belong here: Morrowind uses LEVC for hostile actor spawns, and humanoid
    # enemies are NPC records. Excluding them would reject `db_assassins` (the Dark
    # Brotherhood attack driving Tribunal's main quest), Bloodmoon's berserkers,
    # reavers, smugglers and werewolves, and every vampire cattle list.
    creature_levelled_list_entry: @actor ++ [:creature_levelled_list],
    item_involvement: @item
  }

  @sites Map.new(@sites, fn {site, types} -> {site, Enum.sort(types)} end)

  @doc "The object types a given reference site accepts."
  def allowed(site), do: Map.fetch!(@sites, site)

  @doc "Whether `type` may be referenced from `site`."
  def allows?(site, type), do: type in allowed(site)

  @doc "Every reference site with a declared set of allowed types."
  def sites, do: Map.keys(@sites)

  # Mapping from type atom to resource module
  def type_to_resource(type) do
    Map.fetch!(@types, type)
  end

  def resource_to_type(type) do
    Enum.find(@types, fn {_, name} -> name == type end)
    |> elem(0)
  end
end
