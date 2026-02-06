defmodule Resdayn.Importer.Quests.AnalyzerTest do
  # use Resdayn.IntegrationCase
  use Resdayn.DataCase, async: true

  setup_all do
    # Add quests here as you write new tests that need them analyzed
    Resdayn.Importer.Quests.Analyzer.analyze(["MV_DeadTaxman", "MV_SlaveMule", "TG_LootAldruhnMG"])
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

    test "from range narrowed to 0 when no journal indices exist below from_max", %{"MV_DeadTaxman" => taxman} do
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

    test "from range narrowed when only one journal index exists in range", %{"MV_DeadTaxman" => taxman} do
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

  describe "key NPCs" do
    test "direct dialogue speakers", %{"MV_DeadTaxman" => taxman} do
      assert Ash.CiString.new("chargen class") in taxman.key_npcs
      assert Ash.CiString.new("thavere vedrano") in taxman.key_npcs
      assert Ash.CiString.new("foryn gilnith") in taxman.key_npcs
    end

    test "NPCs with related scripts attached", %{"MV_DeadTaxman" => taxman} do
      assert Ash.CiString.new("processus vitellius") in taxman.key_npcs
    end

    test "NPCs referenced in followed scripts", %{"TG_LootAldruhnMG" => loot_mg} do
      # TG_LootMG disables these NPCs, TG_LootMG2 re-enables them
      assert Ash.CiString.new("erranil") in loot_mg.key_npcs
      assert Ash.CiString.new("movis darys") in loot_mg.key_npcs
      assert Ash.CiString.new("edwinna elbert") in loot_mg.key_npcs
      assert Ash.CiString.new("anarenen") in loot_mg.key_npcs
    end
  end

  describe "key dialogue topics" do
    test "dialogue with direct transitions", %{"MV_DeadTaxman" => taxman} do
      assert Ash.CiString.new("seen him get angry") in taxman.dialogue_topics
      assert Ash.CiString.new("murder of Processus Vitellius") in taxman.dialogue_topics
      assert Ash.CiString.new("Processus' Ring") in taxman.dialogue_topics
    end
  end

  describe "key locations" do
    test "direct dialogue speaker locations", %{"MV_DeadTaxman" => taxman} do
      assert Ash.CiString.new("Seyda Neen, Lighthouse") in taxman.key_locations
      assert Ash.CiString.new("Seyda Neen, Census and Excise Office") in taxman.key_locations
      assert Ash.CiString.new("Seyda Neen, Foryn Gilnith's Shack") in taxman.key_locations
    end

    test "NPCs with related script locations", %{"MV_DeadTaxman" => taxman} do
      assert Ash.CiString.new("-3,-9") in taxman.key_locations
    end
  end

  describe "key items" do
    test "items referenced in dialogue conditions", %{"MV_DeadTaxman" => taxman} do
      assert Ash.CiString.new("bk_seydaneentaxrecord") in taxman.key_items
    end

    test "items transferred in dialogue script effects", %{"MV_DeadTaxman" => taxman} do
      assert Ash.CiString.new("exquisite_ring_processus") in taxman.key_items
    end
  end

  def ci_eq(a, b), do: Ash.CiString.compare(Ash.CiString.new(a), Ash.CiString.new(b)) == :eq

  def find_transition(%Resdayn.Codex.QuestAnalysis.Analysis{} = analysis, index) do
    transition = Enum.find(analysis.transitions, &(&1.index == index))
    refute is_nil(transition)

    transition
  end
end
