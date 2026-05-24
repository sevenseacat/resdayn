defmodule Resdayn.Importer.Quests.AnalyzerTest do
  # use Resdayn.IntegrationCase
  use Resdayn.DataCase, async: true

  setup_all do
    # Add quests here as you write new tests that need them analyzed
    Resdayn.Importer.Quests.Analyzer.analyze([
      "MV_DeadTaxman",
      "MV_SlaveMule",
      "TG_LootAldruhnMG",
      "A1_4_MuzgobInformant"
    ])
  end

  describe "journal entries" do
    test "includes finish/restart flags", %{"MV_SlaveMule" => slavemule} do
      entry = Enum.find(slavemule.journal_entries, &(&1.index == 112))
      refute is_nil(entry)
      assert entry.restart? == true
      assert entry.finish? == false

      entry = Enum.find(slavemule.journal_entries, &(&1.index == 113))
      refute is_nil(entry)
      assert entry.restart? == false
      assert entry.finish? == true
    end
  end

  describe "transitions" do
    test "script updates", %{"MV_DeadTaxman" => taxman} do
      transition = find_transition(taxman, 10)

      assert transition.trigger_type == :script
      assert ci_eq(transition.trigger_id, "processusScript")
    end

    test "from range narrowed to 0 when no journal indices exist below from_max", %{
      "MV_DeadTaxman" => taxman
    } do
      # Transition to index 10 has from_max: 9 (set by script).
      # There are no journal indices in 0-9, so this must be the quest
      # start point: from_min and from_max should both be 0.
      transition = find_transition(taxman, 10)

      assert transition.from_min == 0
      assert transition.from_max == 0
    end

    test "dialogue updates", %{"MV_DeadTaxman" => taxman} do
      transition = find_transition(taxman, 90)

      assert transition.trigger_type == :dialogue_response
      assert transition.trigger_id == Ash.CiString.new("132381979266658957")
      assert transition.trigger_topic_id == Ash.CiString.new("Processus' Ring")
    end

    test "from_min/from_max from journal conditions", %{"MV_DeadTaxman" => taxman} do
      transition = find_transition(taxman, 100)

      assert transition.from_min == 70
      assert transition.from_max == 99
    end

    test "from_min inferred from topic availability (dialogue)", %{"MV_DeadTaxman" => taxman} do
      # The topic "seen him get angry" is first mentioned in dialogue when
      # MV_DeadTaxman is between 48-50. The transition to index 60 uses this
      # topic, so from_min should be at least 48 even though the response
      # itself has no lower bound condition.
      transition = find_transition(taxman, 60)

      assert transition.trigger_topic_id == Ash.CiString.new("seen him get angry")
      assert transition.from_min == 48
    end

    test "from_min inferred from topic availability (script)", %{"MV_DeadTaxman" => taxman} do
      # The topic "murder of Processus Vitellius" is added by processusScript,
      # the same script that sets journal index 10. The transition to index 20
      # uses this topic, so from_min should be 10.
      transition = find_transition(taxman, 20)

      assert transition.trigger_topic_id == Ash.CiString.new("murder of Processus Vitellius")
      assert transition.from_min == 10
    end

    test "from range narrowed when only one journal index exists in range", %{
      "MV_DeadTaxman" => taxman
    } do
      # Transition to index 20 has from_min: 10, from_max: 19 from topic
      # availability. Since 10 is the only journal index in that range,
      # both bounds should narrow to 10.
      transition = find_transition(taxman, 20)

      assert transition.from_min == 10
      assert transition.from_max == 10
    end

    test "from_min inferred from choice chain parent", %{"MV_DeadTaxman" => taxman} do
      # Choice-conditioned responses don't have journal conditions - they have
      # "choice == N" conditions instead. The from_min should be inferred from
      # the parent response that presented the choice AND set the journal.
      #
      # For MV_DeadTaxman:
      # - A response sets journal to 20 and presents choices 1, 2, 3
      # - Choice handlers (indices 30, 40, 45) should have from_min = 20
      # - A response sets journal to 70 and presents choices 5, 6
      # - Choice handlers (indices 80, 85) should have from_min = 70

      # Choice 1 -> journal 30 (honest about gold)
      transition_30 = find_transition(taxman, 30)
      assert transition_30.from_min == 20

      # Choice 2 -> journal 40 (lied about gold)
      transition_40 = find_transition(taxman, 40)
      assert transition_40.from_min == 20

      # Choice 3 -> journal 45 (spent the gold)
      transition_45 = find_transition(taxman, 45)
      assert transition_45.from_min == 20

      # Choice 5 -> journal 80 (believe Gilnith)
      transition_80 = find_transition(taxman, 80)
      assert transition_80.from_min == 70

      # Choice 6 -> journal 85 (don't believe, Gilnith attacks)
      transition_85 = find_transition(taxman, 85)
      assert transition_85.from_min == 70
    end
  end

  describe "related NPCs" do
    test "direct dialogue speakers", %{"MV_DeadTaxman" => taxman} do
      assert find_related_npc(taxman, "chargen class").reason == :dialogue_speaker
      assert find_related_npc(taxman, "thavere vedrano").reason == :dialogue_speaker
      assert find_related_npc(taxman, "foryn gilnith").reason == :dialogue_speaker
    end

    test "NPCs with related scripts attached", %{"MV_DeadTaxman" => taxman} do
      assert find_related_npc(taxman, "processus vitellius").reason == :script_bearer
    end

    test "NPCs referenced in followed scripts", %{"TG_LootAldruhnMG" => loot_mg} do
      # TG_LootMG disables these NPCs, TG_LootMG2 re-enables them
      assert find_related_npc(loot_mg, "erranil").reason == :effect_target
      assert find_related_npc(loot_mg, "movis darys").reason == :effect_target
      assert find_related_npc(loot_mg, "edwinna elbert").reason == :effect_target
      assert find_related_npc(loot_mg, "anarenen").reason == :effect_target
    end

    test "quest giver flag", quests do
      assert find_related_npc(quests["MV_DeadTaxman"], "processus vitellius").quest_giver?
      refute find_related_npc(quests["MV_DeadTaxman"], "foryn gilnith").quest_giver?

      assert find_related_npc(quests["MV_SlaveMule"], "relam arinith").quest_giver?
      refute find_related_npc(quests["MV_SlaveMule"], "rabinna").quest_giver?

      assert find_related_npc(quests["TG_LootAldruhnMG"], "aengoth").quest_giver?
      refute find_related_npc(quests["TG_LootAldruhnMG"], "erranil").quest_giver?

      assert find_related_npc(quests["A1_4_MuzgobInformant"], "caius cosades").quest_giver?
      refute find_related_npc(quests["A1_4_MuzgobInformant"], "sharn gra-muzgob").quest_giver?
    end

    test "quest finisher flag", quests do
      assert find_related_npc(quests["MV_DeadTaxman"], "chargen class").quest_finisher?
      refute find_related_npc(quests["MV_DeadTaxman"], "foryn gilnith").quest_finisher?

      # Rabinna does technically finish this quest if you kill her
      assert find_related_npc(quests["MV_SlaveMule"], "im_kilaya").quest_finisher?
      assert find_related_npc(quests["MV_SlaveMule"], "vorar helas").quest_finisher?
      assert find_related_npc(quests["MV_SlaveMule"], "rabinna").quest_finisher?
      refute find_related_npc(quests["MV_SlaveMule"], "relam arinith").quest_finisher?

      assert find_related_npc(quests["TG_LootAldruhnMG"], "aengoth").quest_finisher?
      refute find_related_npc(quests["TG_LootAldruhnMG"], "anarenen").quest_finisher?
    end
  end

  describe "key dialogue topics" do
    test "dialogue with direct transitions", %{"MV_DeadTaxman" => taxman} do
      assert Ash.CiString.new("seen him get angry") in taxman.dialogue_topics
      assert Ash.CiString.new("murder of Processus Vitellius") in taxman.dialogue_topics
      assert Ash.CiString.new("Processus' Ring") in taxman.dialogue_topics
    end
  end

  describe "related locations" do
    test "direct dialogue speaker locations link to the speaker NPC", %{"MV_DeadTaxman" => taxman} do
      assert Ash.CiString.new("thavere vedrano") in find_related_location(
               taxman,
               "Seyda Neen, Lighthouse"
             ).npc_ids
    end

    test "a cell with both an NPC and quest items links to both sources", %{
      "MV_DeadTaxman" => taxman
    } do
      # Processus's corpse is at exterior cell -3,-9; his inventory contains
      # the tax record (a condition item) so the cell has both NPC and item sources.
      loc = find_related_location(taxman, "-3,-9")
      assert Ash.CiString.new("processus vitellius") in loc.npc_ids
      assert Ash.CiString.new("bk_seydaneentaxrecord") in loc.item_ids
    end

    test "location inferred from unique item cell reference links to the item",
         %{"A1_4_MuzgobInformant" => muzgob} do
      # misc_Skull_Llevule has exactly 1 cell reference: Andrano Ancestral Tomb.
      loc = find_related_location(muzgob, "Andrano Ancestral Tomb")
      assert Ash.CiString.new("misc_Skull_Llevule") in loc.item_ids
      assert loc.npc_ids == []
    end
  end

  describe "related items" do
    test "items referenced in dialogue conditions get a :required use",
         %{"MV_DeadTaxman" => taxman} do
      item = find_related_item(taxman, "bk_seydaneentaxrecord")
      assert Enum.any?(item.uses, &(&1.role == :required))
    end

    test "an item that's both required and surrendered keeps both uses",
         %{"MV_DeadTaxman" => taxman} do
      # The ring appears in a dialogue condition (player must have it) AND is
      # surrendered via removeitem when given to Thavere -- both at journal 90.
      # The two uses share a transition_id but have different roles.
      uses = find_related_item(taxman, "exquisite_ring_processus").uses

      assert Enum.any?(uses, &(&1.role == :required))
      assert Enum.any?(uses, &(&1.role == :surrendered))
    end

    test "items added to the player are :received at the linked transition",
         %{"MV_DeadTaxman" => taxman} do
      # Thavere's response at Journal 90 has `removeitem subject=:self` (her
      # potions) and `player->additem` (player gains the potions). Only the
      # :player-subjected effect counts -- net is :received, not :surrendered.
      potion = find_related_item(taxman, "p_restore_health_s")

      assert potion.uses == [
               %{role: :received, transition_id: "132381979266658957_90"}
             ]
    end

    test "gold is captured as a related item with per-transition uses",
         %{"MV_DeadTaxman" => taxman} do
      # Gold used to be filtered out as too noisy; it's now retained because
      # which transitions involve gold is real quest information.
      gold = find_related_item(taxman, "gold_001")

      # Gold appears in multiple transitions across the quest's branching paths.
      assert Enum.any?(gold.uses, &(&1.role == :required))
      assert Enum.any?(gold.uses, &(&1.role == :surrendered))
      assert Enum.any?(gold.uses, &(&1.role == :received))
    end
  end

  defp ci_eq(a, b), do: Ash.CiString.compare(Ash.CiString.new(a), Ash.CiString.new(b)) == :eq

  defp find_transition(%Resdayn.Codex.QuestAnalysis.Analysis{} = analysis, index) do
    transition = Enum.find(analysis.transitions, &(&1.index == index))
    refute is_nil(transition)

    transition
  end

  defp find_related_npc(%Resdayn.Codex.QuestAnalysis.Analysis{} = analysis, npc_id) do
    related = Enum.find(analysis.related_npcs, &ci_eq(&1.npc_id, npc_id))
    refute is_nil(related), "Expected #{npc_id} to be a related NPC but was not"

    related
  end

  defp find_related_item(%Resdayn.Codex.QuestAnalysis.Analysis{} = analysis, item_id) do
    related = Enum.find(analysis.related_items, &ci_eq(&1.item_id, item_id))
    refute is_nil(related), "Expected #{item_id} to be a related item but was not"

    related
  end

  defp find_related_location(%Resdayn.Codex.QuestAnalysis.Analysis{} = analysis, cell_id) do
    related = Enum.find(analysis.related_locations, &ci_eq(&1.cell_id, cell_id))
    refute is_nil(related), "Expected #{cell_id} to be a related location but was not"

    related
  end
end
