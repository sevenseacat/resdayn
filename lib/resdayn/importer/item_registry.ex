defmodule Resdayn.Importer.ItemRegistry do
  @moduledoc """
  Utilities for building and managing an item type registry during import.
  This registry maps item IDs to their resource types for efficient lookup.
  """

  @item_resources [
    {Resdayn.Codex.Items.Tool, :tool},
    {Resdayn.Codex.Items.Clothing, :clothing},
    {Resdayn.Codex.Items.Weapon, :weapon},
    {Resdayn.Codex.Items.Armor, :armor},
    {Resdayn.Codex.Items.Book, :book},
    {Resdayn.Codex.Items.Ingredient, :ingredient},
    {Resdayn.Codex.Items.Potion, :potion},
    {Resdayn.Codex.Items.AlchemyApparatus, :alchemy_apparatus},
    {Resdayn.Codex.Items.MiscellaneousItem, :miscellaneous_item}
  ]

  @doc """
  Builds a registry mapping all item IDs to their resource types.
  Returns a map like %{"item_id" => :item_type, ...}
  """
  def build_registry do
    @item_resources
    |> Enum.reduce(%{}, fn {resource, type}, acc ->
      items = Ash.read!(resource)
      
      item_map = 
        items
        |> Enum.map(&{&1.id, type})
        |> Enum.into(%{})
      
      Map.merge(acc, item_map)
    end)
  end

  @doc """
  Looks up an item type by ID in the registry.
  Returns the item type atom or nil if not found.
  """
  def lookup_item_type(registry, item_id) do
    Map.get(registry, item_id)
  end

  @doc """
  Converts inventory data from parsed format to InventoryEntry format.
  Resolves item types using the provided registry.
  """
  def convert_inventory_data(carried_objects, holder_id, holder_type, registry) do
    carried_objects
    |> Enum.map(fn %{id: item_id, count: count, restocking: restocking} ->
      case lookup_item_type(registry, item_id) do
        nil ->
          IO.warn("Unknown item ID during inventory import: #{item_id} for #{holder_type} #{holder_id}")
          nil

        item_type ->
          %{
            holder_id: holder_id,
            holder_type: holder_type,
            item_id: item_id,
            item_type: item_type,
            count: count,
            restocking: restocking
          }
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Returns the list of item resource modules and their corresponding types.
  """
  def item_resources, do: @item_resources
end