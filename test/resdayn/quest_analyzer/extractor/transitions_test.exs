defmodule Resdayn.QuestAnalyzer.Extractor.TransitionsTest do
  @moduledoc """
  C1 transition-discovery tests, asserted against the real imported corpus.

  Shape invariants apply to every row; per-quest assertions pin known cases
  to their exact expected transitions. Add a new `describe` block per quest
  whose journal structure you've audited.
  """
  use Resdayn.IntegrationCase

  alias Resdayn.QuestAnalyzer.{Extractor, LoadedData}

  setup_all do
    data = LoadedData.load()
    {:ok, data: data, rows: Extractor.Transitions.discover(data)}
  end

  describe "shape (every row)" do
    test "produces rows", %{rows: rows} do
      refute Enum.empty?(rows)
    end

    test "exactly one source kind is set", %{rows: rows} do
      assert Enum.all?(rows, &exactly_one_source?/1)
    end

    test "target_index is a non-negative integer", %{rows: rows} do
      assert Enum.all?(rows, &(is_integer(&1.target_index) and &1.target_index >= 0))
    end

    test "both dialogue and script sources produce rows", %{rows: rows} do
      from_dialogue = Enum.filter(rows, &(not is_nil(&1.dialogue_response_id)))
      from_scripts = Enum.filter(rows, &(not is_nil(&1.script_id)))

      refute Enum.empty?(from_dialogue)
      refute Enum.empty?(from_scripts)
    end
  end

  describe "orphan QuestVersions" do
    test "are skipped (T_Rules_* records produce no transitions)",
         %{data: data, rows: rows} do
      orphan_qv_ids =
        data.quest_versions
        |> Map.values()
        |> Enum.filter(&is_nil(&1.quest_id))
        |> Enum.map(&Resdayn.QuestAnalyzer.Helpers.str(&1.id))
        |> MapSet.new()

      # Confirm orphan QuestVersions actually exist in the corpus before
      # asserting the extractor excludes them.
      refute Enum.empty?(orphan_qv_ids)

      affected = Enum.filter(rows, &MapSet.member?(orphan_qv_ids, &1.quest_version_id))
      assert affected == []
    end
  end

  # --- Per-quest assertions ---------------------------------------------------

  describe "A1_4_MuzgobInformant (Blades Apprentice)" do
    test "8 transitions, all dialogue-sourced, at the expected indices",
         %{rows: rows} do
      quest_rows = transitions_for(rows, "a1_4_muzgobinformant")

      assert length(quest_rows) == 8
      assert Enum.all?(quest_rows, &(not is_nil(&1.dialogue_response_id)))

      indices = quest_rows |> Enum.map(& &1.target_index) |> Enum.sort()
      assert indices == [1, 10, 12, 15, 20, 25, 30, 55]
    end
  end

  describe "TG_LootAldruhnMG (Loot the Mages Guild)" do
    test "2 transitions on topic 'anareren's devil tanto'", %{rows: rows} do
      quest_rows = transitions_for(rows, "tg_lootaldruhnmg")

      assert length(quest_rows) == 2
      assert Enum.all?(quest_rows, &(not is_nil(&1.dialogue_response_id)))

      assert Enum.all?(
               quest_rows,
               &(to_string(&1.dialogue_response_topic_id) == "anareren's devil tanto")
             )

      indices = quest_rows |> Enum.map(& &1.target_index) |> Enum.sort()
      assert indices == [10, 100]
    end
  end

  describe "MV_DeadTaxman" do
    test "16 transitions mixing 1 script-sourced + 15 dialogue", %{rows: rows} do
      quest_rows = transitions_for(rows, "mv_deadtaxman")

      assert length(quest_rows) == 16

      indices = quest_rows |> Enum.map(& &1.target_index) |> Enum.sort()
      assert indices == [10, 20, 20, 30, 40, 45, 46, 48, 48, 50, 60, 70, 80, 85, 90, 100]
    end

    test "processusscript is the sole script-sourced transition, at index 10",
         %{rows: rows} do
      script_rows =
        rows
        |> transitions_for("mv_deadtaxman")
        |> Enum.filter(&(not is_nil(&1.script_id)))

      assert [row] = script_rows
      assert to_string(row.script_id) == "processusscript"
      assert row.target_index == 10
    end
  end

  describe "MV_SlaveMule" do
    test "21 transitions, sorted indices match the expected multiset",
         %{rows: rows} do
      quest_rows = transitions_for(rows, "mv_slavemule")

      assert length(quest_rows) == 21

      indices = quest_rows |> Enum.map(& &1.target_index) |> Enum.sort()

      assert indices == [
               10, 20, 30, 40, 65, 75, 75, 95, 100,
               101, 102, 103, 103, 108, 109, 111, 112, 113, 113, 114, 115
             ]
    end

    test "script sources write the expected (script, index) pairs", %{rows: rows} do
      pairs =
        rows
        |> transitions_for("mv_slavemule")
        |> Enum.filter(&(not is_nil(&1.script_id)))
        |> Enum.map(&{to_string(&1.script_id), &1.target_index})
        |> Enum.sort()

      # rabinna_death writes TWO journal indices (101 and 114) — one script
      # can advance the quest at multiple call sites.
      assert pairs == [
               {"attack_slave", 102},
               {"rabinna_death", 101},
               {"rabinna_death", 114}
             ]
    end
  end

  defp transitions_for(rows, quest_version_id) do
    Enum.filter(rows, &(&1.quest_version_id == quest_version_id))
  end

  defp exactly_one_source?(row) do
    has_dialogue =
      not is_nil(row.dialogue_response_id) and not is_nil(row.dialogue_response_topic_id)

    has_script = not is_nil(row.script_id)
    has_dialogue != has_script
  end
end
