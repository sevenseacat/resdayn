defmodule Resdayn.QuestAnalyzer.Extractor.Transitions.Preconditions.NarrowTest do
  @moduledoc """
  Range-narrowing tests, asserted against the real imported corpus.

  Narrowing runs over discovered transition rows, using each quest version's
  known journal-entry indices to collapse ambiguous ranges:

  - exactly one known index in `[from_min, from_max]` → pin both to it
  - no known index in range → the quest's entry point, `{0, 0}`
  - many known indices → left ambiguous

  Expected values are derived from MV_DeadTaxman's journal indices
  `[10, 20, 30, 40, 45, 46, 48, 50, 60, 70, 80, 85, 90, 100]`.
  """
  use Resdayn.IntegrationCase

  import Resdayn.TransitionTestHelpers

  alias Resdayn.QuestAnalyzer.{Extractor, LoadedData}
  alias Resdayn.QuestAnalyzer.Extractor.Transitions.Preconditions.Narrow

  setup_all do
    data = LoadedData.load()
    rows = data |> Extractor.Transitions.discover() |> Narrow.apply(data)
    {:ok, rows: rows}
  end

  describe "MV_DeadTaxman (Death of a Taxman)" do
    test "processusscript target 10 narrows to the quest start {0, 0}", %{rows: rows} do
      # The source condition `journal_index < 10` gives an upper bound of 9.
      # No journal entry exists below 10, so the only state it can fire from
      # is the unstarted quest.
      row =
        find_transition(rows,
          quest_version_id: "mv_deadtaxman",
          target_index: 10,
          script_id: "processusscript"
        )

      assert row.from_min == 0
      assert row.from_max == 0
    end

    test "dialogue target 20 (journal < 20) pins to the single known index 10", %{rows: rows} do
      # Upper bound 19; 10 is the only known index in [0, 19].
      row =
        find_transition(rows,
          quest_version_id: "mv_deadtaxman",
          target_index: 20,
          dialogue_response_id: "242392067944577534"
        )

      assert row.from_min == 10
      assert row.from_max == 10
    end

    test "dialogue target 46 (journal = 45) stays pinned at {45, 45}", %{rows: rows} do
      row =
        find_transition(rows,
          quest_version_id: "mv_deadtaxman",
          target_index: 46,
          dialogue_response_id: "4145450230103435"
        )

      assert row.from_min == 45
      assert row.from_max == 45
    end

    test "dialogue target 50 stays ambiguous at {48, 70}", %{rows: rows} do
      # [48, 70] holds 48, 50, 60, 70 — more than one known index, so the
      # range can't be pinned and is left untouched.
      row =
        find_transition(rows,
          quest_version_id: "mv_deadtaxman",
          target_index: 50,
          dialogue_response_id: "2182878901212026068"
        )

      assert row.from_min == 48
      assert row.from_max == 70
    end

    test "dialogue target 30 (no journal condition) stays {nil, nil}", %{rows: rows} do
      # from_max is nil — there's no upper bound to narrow against.
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
    test "rabinna_death target 101 stays ambiguous and keeps a nil from_min", %{rows: rows} do
      # Upper bound 100 (journal_index <= 100), no lower bound. Many known
      # indices sit in [0, 100], so the range can't be pinned — and narrowing
      # must not fabricate a from_min where the source gave none.
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

  describe "shape (every row)" do
    test "from_min <= from_max wherever both are set", %{rows: rows} do
      rows
      |> Enum.filter(&(&1.from_min && &1.from_max))
      |> Enum.each(fn row -> assert row.from_min <= row.from_max end)
    end

    test "no two rows are byte-identical after narrowing", %{rows: rows} do
      # Narrowing can collapse two distinct ranges (e.g. both to {0, 0}); any
      # rows it makes identical must be deduped so the persister stays clean.
      assert length(rows) == length(Enum.uniq(rows))
    end
  end
end
