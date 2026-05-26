defmodule Resdayn.QuestAnalyzer.PersisterTest do
  @moduledoc """
  Tests for the persister that writes extractor row lists into the
  QuestAnalysis tables.
  """
  use Resdayn.IntegrationCase

  require Ash.Query

  alias Resdayn.Codex.QuestAnalysis.NPCInvolvement
  alias Resdayn.QuestAnalyzer.{Extractor, LoadedData, Persister}

  setup do
    Resdayn.Repo.query!("TRUNCATE npc_involvements")
    :ok
  end

  describe "npc_involvements/1" do
    test "persists extractor rows for a known quest" do
      data = LoadedData.load(["A1_4_MuzgobInformant"])
      rows = Extractor.Characters.dialogue_speakers(data)
      refute Enum.empty?(rows)

      Persister.npc_involvements(rows)

      count =
        NPCInvolvement
        |> Ash.Query.filter(quest_version_id == "a1_4_muzgobinformant")
        |> Ash.count!()

      assert count == length(rows)
    end

    test "is idempotent — re-running with the same rows doesn't duplicate" do
      data = LoadedData.load(["A1_4_MuzgobInformant"])
      rows = Extractor.Characters.dialogue_speakers(data)

      Persister.npc_involvements(rows)
      first_count = Ash.count!(NPCInvolvement)

      Persister.npc_involvements(rows)
      second_count = Ash.count!(NPCInvolvement)

      assert first_count == second_count
    end
  end
end
