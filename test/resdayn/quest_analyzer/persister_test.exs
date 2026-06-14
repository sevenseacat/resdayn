defmodule Resdayn.QuestAnalyzer.PersisterTest do
  @moduledoc """
  Tests for the persister that writes extractor row lists into the
  QuestAnalysis tables.
  """
  use Resdayn.IntegrationCase

  require Ash.Query

  alias Resdayn.Codex.QuestAnalysis.{ActorInvolvement, Transition}
  alias Resdayn.QuestAnalyzer.{Extractor, LoadedData, Persister}

  setup do
    Resdayn.Repo.query!("TRUNCATE actor_involvements")
    Resdayn.Repo.query!("TRUNCATE transitions")
    :ok
  end

  describe "actor_involvements/1" do
    test "persists extractor rows for a known quest" do
      data = LoadedData.load(["A1_4_MuzgobInformant"])
      rows = Extractor.Actors.dialogue_speakers(data)
      refute Enum.empty?(rows)

      Persister.actor_involvements(rows)

      count =
        ActorInvolvement
        |> Ash.Query.filter(quest_version_id == "a1_4_muzgobinformant")
        |> Ash.count!()

      assert count == length(rows)
    end

    test "is idempotent — re-running with the same rows doesn't duplicate" do
      data = LoadedData.load(["A1_4_MuzgobInformant"])
      rows = Extractor.Actors.dialogue_speakers(data)

      Persister.actor_involvements(rows)
      first_count = Ash.count!(ActorInvolvement)

      Persister.actor_involvements(rows)
      second_count = Ash.count!(ActorInvolvement)

      assert first_count == second_count
    end
  end

  describe "transitions/1" do
    test "persists every extractor row, including distinct same-index edges" do
      data = LoadedData.load(["MG_Excavation"])
      rows = Extractor.Transitions.discover(data)

      Persister.transitions(rows)

      assert Ash.count!(Transition) == length(rows)

      # hgwcscript reaches index 40 via two condition paths with different
      # journal bounds — both are distinct edges and must both persist.
      same_index_edges =
        Transition
        |> Ash.Query.filter(
          quest_version_id == "mg_excavation" and target_index == 40 and script_id == "hgwcscript"
        )
        |> Ash.read!()
        |> Enum.map(&{&1.from_min, &1.from_max})
        |> Enum.sort()

      assert same_index_edges == [{nil, 39}, {nil, nil}]
    end

    test "is idempotent — re-running clears and rebuilds rather than duplicating" do
      data = LoadedData.load(["MG_Excavation"])
      rows = Extractor.Transitions.discover(data)

      Persister.transitions(rows)
      first_count = Ash.count!(Transition)

      Persister.transitions(rows)
      second_count = Ash.count!(Transition)

      assert first_count == second_count
    end
  end
end
