defmodule Resdayn.QuestAnalyzerTest do
  @moduledoc """
  End-to-end tests for the quest analyzer: load → extract → persist, then
  query the persisted involvement table for known cases.
  """
  use Resdayn.IntegrationCase

  require Ash.Query

  alias Resdayn.Catalog.QuestAnalysis.ActorInvolvement

  setup do
    Resdayn.Repo.query!("TRUNCATE actor_involvements, item_involvements, transitions")
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
        Resdayn.Catalog.Dialogue.QuestVersion
        |> Ash.get!("A1_4_MuzgobInformant", load: [quest: :related_npcs])
        |> Map.fetch!(:quest)

      refute Enum.empty?(quest.related_npcs)

      assert Enum.all?(quest.related_npcs, &match?(%Resdayn.Catalog.World.NPC{}, &1.actor))
      assert Enum.any?(quest.related_npcs, &(:dialogue_speaker in &1.roles))

      # Each entry's primary_role is its most important role, and the most
      # central actors are listed first.
      alias Resdayn.Catalog.QuestAnalysis.ActorInvolvement.Reason

      assert Enum.all?(quest.related_npcs, fn entry ->
               entry.primary_role == Enum.min_by(entry.roles, &Reason.importance/1)
             end)

      primary_ranks = Enum.map(quest.related_npcs, &Reason.importance(&1.primary_role))
      assert primary_ranks == Enum.sort(primary_ranks)
    end

    test "counts and sorts quests by involved actor headcount" do
      Resdayn.QuestAnalyzer.run(["A1_4_MuzgobInformant"])

      quest =
        Resdayn.Catalog.Dialogue.QuestVersion
        |> Ash.get!("A1_4_MuzgobInformant",
          load: [quest: [:npc_count, :creature_count, :actor_count]]
        )
        |> Map.fetch!(:quest)

      assert quest.npc_count > 0
      assert quest.actor_count == quest.npc_count + quest.creature_count

      # The combined count pushes down to SQL, so it's usable as a sort key.
      sorted =
        Resdayn.Catalog.Dialogue.Quest
        |> Ash.Query.sort(actor_count: :desc)
        |> Ash.Query.load(:actor_count)
        |> Ash.read!()

      counts = Enum.map(sorted, & &1.actor_count)
      assert counts == Enum.sort(counts, :desc)
      assert Enum.max(counts) == quest.actor_count
    end

    test "exposes related_quests as a loadable calculation on an NPC" do
      Resdayn.QuestAnalyzer.run(["A1_4_MuzgobInformant"])

      npc = Ash.get!(Resdayn.Catalog.World.NPC, "caius cosades", load: :related_quests)

      refute Enum.empty?(npc.related_quests)

      assert Enum.all?(npc.related_quests, &match?(%Resdayn.Catalog.Dialogue.Quest{}, &1.quest))
      assert Enum.any?(npc.related_quests, &(:dialogue_speaker in &1.roles))

      # Each entry's primary_role is its most important role, and the quests
      # where this actor is most central are listed first.
      alias Resdayn.Catalog.QuestAnalysis.ActorInvolvement.Reason

      assert Enum.all?(npc.related_quests, fn entry ->
               entry.primary_role == Enum.min_by(entry.roles, &Reason.importance/1)
             end)

      primary_ranks = Enum.map(npc.related_quests, &Reason.importance(&1.primary_role))
      assert primary_ranks == Enum.sort(primary_ranks)
    end

    test "exposes related_quest_count on an NPC" do
      Resdayn.QuestAnalyzer.run(["A1_4_MuzgobInformant"])

      npc = Ash.get!(Resdayn.Catalog.World.NPC, "caius cosades", load: [:related_quest_count])

      # Only this one quest was analyzed, so there's a single distinct related
      # quest — even though the NPC has multiple involvement rows for it (one
      # join row each), the uniq? aggregate collapses them to a count of 1.
      assert npc.related_quest_count == 1
    end

    test "Quest.related_dialogue_topics surfaces topics with faction-only speakers (Morag Tong writs)" do
      # MT_WritGalasa's writ-giving dialogue is spoken by any Morag Tong member
      # of the right rank, not a specific NPC — so ActorInvolvement produces no
      # rows for this quest. Walking through `transitions` (which depends only
      # on the `Journal X N` call site, not on speaker resolution) restores the
      # topic.
      Resdayn.QuestAnalyzer.run(["MT_WritGalasa"])

      quest =
        Resdayn.Catalog.Dialogue.QuestVersion
        |> Ash.get!("MT_WritGalasa", load: [quest: :related_dialogue_topics])
        |> Map.fetch!(:quest)

      topics =
        Enum.map(quest.related_dialogue_topics, &(&1 |> to_string() |> String.downcase()))

      assert "galasa uvayn" in topics
    end

    test "Topic.related_quests surfaces quests gated by faction-only speakers" do
      Resdayn.QuestAnalyzer.run(["MT_WritGalasa"])

      topic =
        Ash.get!(Resdayn.Catalog.Dialogue.Topic, "galasa uvayn",
          load: [:related_quests, :related_quest_count]
        )

      quest_ids = topic.related_quests |> Enum.map(&to_string(&1.id))
      assert "morag-tong-writ-for-galasa-uvayn" in quest_ids
      assert topic.related_quest_count >= 1
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
