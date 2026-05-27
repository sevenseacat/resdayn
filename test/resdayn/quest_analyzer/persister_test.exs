defmodule Resdayn.QuestAnalyzer.PersisterTest do
  @moduledoc """
  Tests for the persister that writes extractor row lists into the
  QuestAnalysis tables.
  """
  use Resdayn.IntegrationCase

  require Ash.Query

  alias Resdayn.Codex.QuestAnalysis.ActorInvolvement
  alias Resdayn.QuestAnalyzer.{Extractor, LoadedData, Persister}

  setup do
    Resdayn.Repo.query!("TRUNCATE actor_involvements")
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
end
