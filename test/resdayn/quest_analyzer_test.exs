defmodule Resdayn.QuestAnalyzerTest do
  @moduledoc """
  End-to-end tests for the quest analyzer: load → extract → persist, then
  query the persisted involvement table for known cases.
  """
  use Resdayn.IntegrationCase

  require Ash.Query

  alias Resdayn.Codex.QuestAnalysis.ActorInvolvement

  setup do
    Resdayn.Repo.query!("TRUNCATE actor_involvements")
    :ok
  end

  describe "run/1" do
    test "persists actor involvements for a filtered quest set" do
      counts = Resdayn.QuestAnalyzer.run(["A1_4_MuzgobInformant"])

      assert counts.actor_involvements > 0

      # Caius is the quest giver — appears as both dialogue_speaker (4 responses)
      # and effect_target/mention rows in his responses' effects.
      caius_rows =
        ActorInvolvement
        |> Ash.Query.filter(
          quest_version_id == "a1_4_muzgobinformant" and npc_id == "caius cosades"
        )
        |> Ash.read!()

      reasons = caius_rows |> Enum.map(& &1.reason) |> Enum.uniq() |> Enum.sort()
      assert :dialogue_speaker in reasons
    end

    test "exposes related_npcs as a loadable calculation on the quest concept" do
      Resdayn.QuestAnalyzer.run(["A1_4_MuzgobInformant"])

      quest =
        Resdayn.Codex.Dialogue.QuestVersion
        |> Ash.get!("A1_4_MuzgobInformant", load: [quest: :related_npcs])
        |> Map.fetch!(:quest)

      refute Enum.empty?(quest.related_npcs)

      assert Enum.all?(quest.related_npcs, &match?(%Resdayn.Codex.World.NPC{}, &1.actor))
      assert Enum.any?(quest.related_npcs, &(:dialogue_speaker in &1.roles))
    end

    test "is idempotent" do
      Resdayn.QuestAnalyzer.run(["A1_4_MuzgobInformant"])
      first = Ash.count!(ActorInvolvement)

      Resdayn.QuestAnalyzer.run(["A1_4_MuzgobInformant"])
      second = Ash.count!(ActorInvolvement)

      assert first == second
    end
  end
end
