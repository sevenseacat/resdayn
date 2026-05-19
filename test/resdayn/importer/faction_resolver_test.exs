defmodule Resdayn.Importer.FactionResolverTest do
  use ExUnit.Case, async: true

  alias Resdayn.Importer.FactionResolver

  defp factions do
    [
      # Vanilla
      %{id: "Mages Guild", name: "Mages Guild"},
      %{id: "Fighters Guild", name: "Fighters Guild"},
      %{id: "Imperial Cult", name: "Imperial Cult"},
      %{id: "Hlaalu", name: "Great House Hlaalu"},
      %{id: "Telvanni", name: "Great House Telvanni"},
      # TR Mainland-only clans
      %{id: "T_Mw_Clan_Baluath", name: "Baluath Clan"},
      %{id: "T_Mw_Clan_Orlukh", name: "Orlukh Clan"},
      # Deprecated TR_Mw_ stubs that should be ignored
      %{id: "T_Mw_HouseHlaalu", name: "<Deprecated>"},
      %{id: "T_Mw_MagesGuild", name: "<Deprecated>"}
    ]
  end

  defp index, do: FactionResolver.build_index(factions())

  describe "build_index/1" do
    test "filters out factions named <Deprecated>" do
      values = Map.values(index())
      refute "T_Mw_HouseHlaalu" in values
      refute "T_Mw_MagesGuild" in values
    end

    test "indexes a faction by its full name" do
      assert index()["Mages Guild"] == "Mages Guild"
    end

    test "indexes a Great House under both full and stripped name" do
      i = index()
      assert i["Great House Hlaalu"] == "Hlaalu"
      assert i["House Hlaalu"] == "Hlaalu"
    end

    test "indexes a T_Mw_Clan_ faction under both full and Clan-stripped name" do
      i = index()
      assert i["Baluath Clan"] == "T_Mw_Clan_Baluath"
      assert i["Baluath"] == "T_Mw_Clan_Baluath"
    end
  end

  describe "resolve/2" do
    test "returns {nil, name} when there is no ': ' separator" do
      assert FactionResolver.resolve("Sleepers Awake", index()) == {nil, "Sleepers Awake"}
    end

    test "returns {nil, full_name} for unknown prefixes" do
      i = index()

      assert FactionResolver.resolve("Bounty: The Masqued Captain", i) ==
               {nil, "Bounty: The Masqued Captain"}

      assert FactionResolver.resolve("College of Firewatch: Enrollment", i) ==
               {nil, "College of Firewatch: Enrollment"}
    end

    test "resolves a vanilla guild by name" do
      assert FactionResolver.resolve("Mages Guild: Apprentice", index()) ==
               {"Mages Guild", "Apprentice"}
    end

    test "resolves 'House X' via Great-House stripping" do
      assert FactionResolver.resolve("House Hlaalu: Disguise", index()) ==
               {"Hlaalu", "Disguise"}
    end

    test "resolves the apostrophe variant via alias" do
      assert FactionResolver.resolve("Fighter's Guild: Debt Stoine", index()) ==
               {"Fighters Guild", "Debt Stoine"}
    end

    test "resolves a TR clan by short name" do
      assert FactionResolver.resolve("Baluath: Hannat", index()) ==
               {"T_Mw_Clan_Baluath", "Hannat"}
    end

    test "resolves a TR clan by full name" do
      assert FactionResolver.resolve("Baluath Clan: Some Quest", index()) ==
               {"T_Mw_Clan_Baluath", "Some Quest"}
    end
  end
end
