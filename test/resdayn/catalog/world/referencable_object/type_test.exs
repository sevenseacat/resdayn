defmodule Resdayn.Catalog.World.ReferencableObject.TypeTest do
  use ExUnit.Case, async: true

  alias Resdayn.Catalog.World.ReferencableObject.Type

  describe "allowed/1" do
    test "every site allows only live object types" do
      for site <- Type.sites() do
        assert Type.allowed(site) -- Type.values() == [],
               "#{site} allows types that are not in Type.values()"
      end
    end

    test "an inventory object and an item levelled list entry accept the same types" do
      assert Type.allowed(:inventory_object) == Type.allowed(:item_levelled_list_entry)
    end

    test "a levelled list may nest within its own kind but not the other" do
      assert Type.allows?(:item_levelled_list_entry, :item_levelled_list)
      refute Type.allows?(:item_levelled_list_entry, :creature_levelled_list)

      assert Type.allows?(:creature_levelled_list_entry, :creature_levelled_list)
      refute Type.allows?(:creature_levelled_list_entry, :item_levelled_list)
    end

    test "a creature levelled list can be placed in a cell but an item levelled list cannot" do
      assert Type.allows?(:cell_reference, :creature_levelled_list)
      refute Type.allows?(:cell_reference, :item_levelled_list)
    end

    test "a container holds inventory but is never itself held or listed" do
      assert Type.allows?(:inventory_holder, :container)
      refute Type.allows?(:inventory_object, :container)
      refute Type.allows?(:item_levelled_list_entry, :container)
    end

    test "only actors and containers hold inventory" do
      assert Type.allowed(:inventory_holder) == [:container, :creature, :npc]
    end

    # Statics are deliberately not imported, so no cell reference in the database
    # points at one. That is an import gap, not a game rule — the CS places statics
    # in cells constantly, and enabling the STAT import must not trip a conformance
    # failure that looks like a data bug.
    test "a static object is placeable in a cell despite never being imported" do
      assert Type.allows?(:cell_reference, :static_object)
    end
  end

  describe "allows?/2" do
    test "is false for a type that exists but is not permitted at that site" do
      assert :door in Type.values()
      refute Type.allows?(:inventory_object, :door)
    end

    test "raises for a site that does not exist" do
      assert_raise KeyError, fn -> Type.allows?(:not_a_site, :weapon) end
    end
  end
end
