defmodule Resdayn.Importer.Quests.AnalyzerTest do
  # use Resdayn.IntegrationCase
  use Resdayn.DataCase, async: true

  setup_all do
    # Add quests here as you write new tests that need them analyzed
    Resdayn.Importer.Quests.Analyzer.analyze(["MV_DeadTaxman", "MV_SlaveMule"])
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

      assert transition.from_max == 9
      assert transition.trigger_type == :script
      assert transition.trigger_id == Ash.CiString.new("processusScript")
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

  def find_transition(%Resdayn.Codex.QuestAnalysis.Analysis{} = analysis, index) do
    transition = Enum.find(analysis.transitions, &(&1.index == index))
    refute is_nil(transition)

    transition
  end
end
