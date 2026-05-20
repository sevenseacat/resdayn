defmodule Resdayn.Importer.Quests.ItemLocationsTest do
  use ExUnit.Case, async: true

  alias Resdayn.Importer.Quests.ItemLocations

  describe "direct cell references" do
    test "uniquely-placed item returns its cell tagged with the source item" do
      index = ItemLocations.build(%{"skull" => "Andrano Ancestral Tomb"}, %{})
      locations = ItemLocations.get_locations(index, ["skull"])

      assert {Ash.CiString.new("Andrano Ancestral Tomb"), Ash.CiString.new("skull")} in locations
    end

    test "item not in unique placements returns nothing" do
      index = ItemLocations.build(%{}, %{})
      locations = ItemLocations.get_locations(index, ["missing_item"])
      assert locations == []
    end

    test "lookup is case-insensitive" do
      index = ItemLocations.build(%{"skull_llevule" => "Andrano Ancestral Tomb"}, %{})
      locations = ItemLocations.get_locations(index, ["Skull_Llevule"])

      assert {Ash.CiString.new("Andrano Ancestral Tomb"), Ash.CiString.new("Skull_Llevule")} in locations
    end
  end

  describe "inventory holders" do
    test "item in uniquely-placed container returns container's cell" do
      index =
        ItemLocations.build(
          %{"chest_anararen" => "Ald-ruhn, Guild of Mages"},
          %{"tanto" => ["chest_anararen"]}
        )

      locations = ItemLocations.get_locations(index, ["tanto"])

      assert {Ash.CiString.new("Ald-ruhn, Guild of Mages"), Ash.CiString.new("tanto")} in locations
    end

    test "item in non-unique container returns nothing" do
      index = ItemLocations.build(%{}, %{"tanto" => ["common_chest"]})
      locations = ItemLocations.get_locations(index, ["tanto"])
      assert locations == []
    end
  end

  describe "add_item targets" do
    test "item added to uniquely-placed container returns container's cell" do
      index = ItemLocations.build(%{"chest_anararen" => "Ald-ruhn, Guild of Mages"}, %{})

      locations =
        ItemLocations.get_locations(index, ["tanto"], %{
          "tanto" => ["chest_anararen"]
        })

      assert {Ash.CiString.new("Ald-ruhn, Guild of Mages"), Ash.CiString.new("tanto")} in locations
    end

    test "add_item target not uniquely placed returns nothing" do
      index = ItemLocations.build(%{}, %{})

      locations =
        ItemLocations.get_locations(index, ["tanto"], %{
          "tanto" => ["common_chest"]
        })

      assert locations == []
    end
  end

  describe "combined paths" do
    test "deduplicates locations across paths" do
      index =
        ItemLocations.build(
          %{"skull" => "Tomb", "urn" => "Tomb"},
          %{"skull" => ["urn"]}
        )

      locations = ItemLocations.get_locations(index, ["skull"])
      assert locations == [{Ash.CiString.new("Tomb"), Ash.CiString.new("skull")}]
    end

    test "multiple condition items each contribute locations" do
      index =
        ItemLocations.build(
          %{"skull" => "Tomb", "notes" => "Guild Hall"},
          %{}
        )

      locations = ItemLocations.get_locations(index, ["skull", "notes"])
      assert {Ash.CiString.new("Tomb"), Ash.CiString.new("skull")} in locations
      assert {Ash.CiString.new("Guild Hall"), Ash.CiString.new("notes")} in locations
    end
  end
end
