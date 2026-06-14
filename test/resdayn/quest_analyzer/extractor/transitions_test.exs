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
      Enum.each(rows, fn row ->
        assert (row.dialogue_response_id && row.dialogue_response_topic_id) || row.script_id
      end)
    end

    test "target_index is a non-negative integer", %{rows: rows} do
      Enum.each(rows, fn row ->
        assert is_integer(row.target_index) && row.target_index >= 0
      end)
    end

    test "both dialogue and script sources produce rows", %{rows: rows} do
      from_dialogue = Enum.filter(rows, &(&1.dialogue_response_id))
      from_scripts = Enum.filter(rows, &(&1.script_id))

      refute Enum.empty?(from_dialogue)
      refute Enum.empty?(from_scripts)
    end

    test "from_min and from_max are each nil-or-integer", %{rows: rows} do
      assert Enum.all?(rows, &(is_nil(&1.from_min) || is_integer(&1.from_min)))
      assert Enum.all?(rows, &(is_nil(&1.from_max) || is_integer(&1.from_max)))
    end

    test "some rows have both bounds populated", %{rows: rows} do
      bounded = Enum.filter(rows, &(&1.from_min && &1.from_max))
      refute Enum.empty?(bounded)
    end

    test "from_min <= from_max wherever both are set", %{rows: rows} do
      rows
      |> Enum.filter(&(&1.from_min && &1.from_max))
      |> Enum.each(fn row -> assert row.from_min <= row.from_max end)
    end

    test "no two rows are byte-identical", %{rows: rows} do
      # Distinct edges to the same index are allowed (they differ in bounds),
      # but two fully-identical rows are pointless — nothing we store tells
      # them apart, so the per-source `Enum.uniq` should have collapsed them.
      assert length(rows) == length(Enum.uniq(rows))
    end
  end

  test "orphan QuestVersions are skipped", %{data: data, rows: rows} do
    orphan_qv_ids =
      data.quest_versions
      |> Map.values()
      |> Enum.filter(&is_nil(&1.quest_id))
      |> Enum.map(&Resdayn.QuestAnalyzer.Helpers.str(&1.id))
      |> MapSet.new()

    # Ensure some orphan QuestVersions actually exist in the corpus before
    # asserting the extractor excludes them.
    refute Enum.empty?(orphan_qv_ids)

    affected = Enum.filter(rows, &MapSet.member?(orphan_qv_ids, &1.quest_version_id))
    assert affected == []
  end

  # --- Per-quest assertions ---------------------------------------------------

  describe "A1_4_MuzgobInformant (Blades Apprentice)" do
    test "8 transitions, all dialogue-sourced, at the expected indices", %{rows: rows} do
      quest_rows = transitions_for(rows, "a1_4_muzgobinformant")

      assert length(quest_rows) == 8
      assert Enum.all?(quest_rows, &(&1.dialogue_response_id))

      indices = quest_rows |> Enum.map(& &1.target_index) |> Enum.sort()
      assert indices == [1, 10, 12, 15, 20, 25, 30, 55]
    end
  end

  describe "TG_LootAldruhnMG (Loot the Mages Guild)" do
    test "2 transitions on topic 'anareren's devil tanto'", %{rows: rows} do
      quest_rows = transitions_for(rows, "tg_lootaldruhnmg")

      assert length(quest_rows) == 2
      assert Enum.all?(quest_rows, &(&1.dialogue_response_id))
      assert Enum.all?(
               quest_rows,
               &Ash.CiString.compare(&1.dialogue_response_topic_id, "anareren's devil tanto") == :eq
             )

      indices = quest_rows |> Enum.map(& &1.target_index) |> Enum.sort()
      assert indices == [10, 100]
    end
  end

  describe "MV_DeadTaxman (Death of a Taxman)" do
    test "16 transitions mixing 1 script-sourced + 15 dialogue", %{rows: rows} do
      quest_rows = transitions_for(rows, "mv_deadtaxman")

      assert length(quest_rows) == 16

      indices = quest_rows |> Enum.map(& &1.target_index) |> Enum.sort()
      assert indices == [10, 20, 20, 30, 40, 45, 46, 48, 48, 50, 60, 70, 80, 85, 90, 100]
    end

    test "processusscript is the sole script-sourced transition, at index 10", %{rows: rows} do
      script_rows =
        rows
        |> transitions_for("mv_deadtaxman")
        |> Enum.filter(&(&1.script_id))

      assert [row] = script_rows
      assert to_string(row.script_id) == "processusscript"
      assert row.target_index == 10
    end

    test "script `journal_index < 10` → from_max = 9 only", %{rows: rows} do
      row =
        find_transition(rows,
          quest_version_id: "mv_deadtaxman",
          target_index: 10,
          script_id: "processusscript"
        )

      assert is_nil(row.from_min)
      assert row.from_max == 9

      # TODO: this is also the start of quest
    end

    test "dialogue `journal < 20` → from_max = 19 only", %{rows: rows} do
      row =
        find_transition(rows,
          quest_version_id: "mv_deadtaxman",
          target_index: 20,
          dialogue_response_id: "242392067944577534"
        )

      assert is_nil(row.from_min)
      assert row.from_max == 19
    end

    test "dialogue `journal = 45` → from_min = from_max = 45", %{rows: rows} do
      row =
        find_transition(rows,
          quest_version_id: "mv_deadtaxman",
          target_index: 46,
          dialogue_response_id: "4145450230103435"
        )

      assert row.from_min == 45
      assert row.from_max == 45
    end

    test "dialogue `journal <= 70 AND journal >= 48` narrows to [48, 70]", %{rows: rows} do
      row =
        find_transition(rows,
          quest_version_id: "mv_deadtaxman",
          target_index: 50,
          dialogue_response_id: "2182878901212026068"
        )

      assert row.from_min == 48
      assert row.from_max == 70
    end

    test "dialogue `journal < 100 AND journal >= 70` narrows to [70, 99]", %{rows: rows} do
      row =
        find_transition(rows,
          quest_version_id: "mv_deadtaxman",
          target_index: 100,
          dialogue_response_id: "222445677129166576"
        )

      assert row.from_min == 70
      assert row.from_max == 99
    end

    test "transition with no relevant journal conditions has nil bounds", %{rows: rows} do
      row =
        find_transition(rows,
          quest_version_id: "mv_deadtaxman",
          target_index: 30,
          dialogue_response_id: "1932910257292029503"
        )

      assert is_nil(row.from_min)
      assert is_nil(row.from_max)
    end
  end

  describe "MV_SlaveMule (Rabinna's Inner Beauty)" do
    test "21 transitions, sorted indices match the expected multiset", %{rows: rows} do
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

    test "dialogue `journal > 10` AND `journal < 103` narrows to [11, 102]", %{rows: rows} do
      row =
        find_transition(rows,
          quest_version_id: "mv_slavemule",
          target_index: 103,
          dialogue_response_id: "215733096575319625"
        )

      assert row.from_min == 11
      assert row.from_max == 102
    end

    test "script `journal_index <= 100` → from_max = 100", %{rows: rows} do
      row =
        find_transition(rows,
          quest_version_id: "mv_slavemule",
          target_index: 101,
          script_id: "rabinna_death"
        )

      assert is_nil(row.from_min)
      assert row.from_max == 100
    end
  end

  describe "MG_Excavation (Mages Guild: Nchuleftingth Expedition)" do
    test "hgwcscript reaches index 40 via two separately-gated edges", %{rows: rows} do
      # One `if` block gates the journal call on `on_activate`/`journal_index < 40`;
      # another on the player's `distance` alone (no journal bound). Reachable
      # if *either* fires, so they're two distinct edges with their own
      # preconditions — not one row to be merged.
      bounds =
        rows
        |> Enum.filter(
          &(&1.quest_version_id == "mg_excavation" and &1.target_index == 40 and
              &1.script_id == "hgwcscript")
        )
        |> Enum.map(&{&1.from_min, &1.from_max})
        |> Enum.sort()

      assert bounds == [{nil, 39}, {nil, nil}]
    end
  end

  defp transitions_for(rows, quest_version_id) do
    Enum.filter(rows, &(&1.quest_version_id == quest_version_id))
  end

  # Find the single transition row matching all of the provided filters. Raises
  # if none / multiple match — the tests pin specific (qv, index, source) tuples
  # so anything else is a setup error.
  defp find_transition(rows, filters) do
    matches =
      Enum.filter(rows, fn row ->
        Enum.all?(filters, fn {key, value} ->
          row_value = Map.get(row, key)
          to_string(row_value) == to_string(value)
        end)
      end)

    case matches do
      [row] -> row
      [] -> raise "no transition matched #{inspect(filters)}"
      many -> raise "#{length(many)} transitions matched #{inspect(filters)} — refine filters"
    end
  end
end
