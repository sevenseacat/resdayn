defmodule Resdayn.QuestAnalyzer.LoadedDataTest do
  @moduledoc """
  Tests for the data-loading layer that builds the `LoadedData` struct
  threaded through the quest analyzer's extractors.
  """
  use Resdayn.IntegrationCase

  alias Resdayn.QuestAnalyzer.LoadedData

  setup_all do
    {:ok, data: LoadedData.load()}
  end

  describe "load/0" do
    test "populates every field", %{data: data} do
      assert %LoadedData{} = data
      refute Enum.empty?(data.quest_versions)
      refute Enum.empty?(data.scripts)
      refute Enum.empty?(data.dialogue_responses)
      refute Enum.empty?(data.npcs)
      refute Enum.empty?(data.creatures)
    end

    test "preloads journal entries on quest versions", %{data: data} do
      quest = Map.fetch!(data.quest_versions, "a1_4_muzgobinformant")
      assert length(quest.journal_entries) == 8
    end

    test "scripts contain parsed journal commands", %{data: data} do
      # processusScript sets journal index 10 for MV_DeadTaxman
      parsed = Map.fetch!(data.scripts, "processusscript")
      assert Enum.any?(parsed, &(&1.quest_id == "mv_deadtaxman" and &1.index == 10))
    end

    test "npcs are loaded with cell info", %{data: data} do
      caius = Map.fetch!(data.npcs, "caius cosades")
      refute is_nil(caius.cell_id)
    end
  end

  describe "load/1" do
    test "filters quest versions to the given ids" do
      data = LoadedData.load(["A1_4_MuzgobInformant"])
      assert Map.keys(data.quest_versions) == ["a1_4_muzgobinformant"]
    end
  end
end
