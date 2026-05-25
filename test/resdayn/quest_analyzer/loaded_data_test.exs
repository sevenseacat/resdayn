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
    end

    test "preloads journal entries on quest versions", %{data: data} do
      quest = Map.fetch!(data.quest_versions, "a1_4_muzgobinformant")
      assert length(quest.journal_entries) == 8
    end
  end

  describe "load/1" do
    test "filters quest versions to the given ids" do
      data = LoadedData.load(["A1_4_MuzgobInformant"])
      assert Map.keys(data.quest_versions) == ["a1_4_muzgobinformant"]
    end
  end
end
