defmodule Resdayn.Catalog.Dialogue.JournalEntryReachabilityTest do
  @moduledoc """
  A journal entry is reachable when some transition in the same quest version
  advances the quest to its index. Entries no transition targets are dead — the
  game ships journal text the player can never see.

  Asserted against the real corpus: MV_SlaveMule has two such entries (105, 110),
  MV_DeadTaxman has none.
  """
  use Resdayn.IntegrationCase

  require Ash.Query

  alias Resdayn.Catalog.Dialogue.JournalEntry
  alias Resdayn.QuestAnalyzer.{Extractor, LoadedData, Persister}
  alias Resdayn.QuestAnalyzer.Extractor.Transitions.Preconditions.Narrow

  setup do
    Resdayn.Repo.query!("TRUNCATE transitions")
    data = LoadedData.load(["MV_SlaveMule", "MV_DeadTaxman", "A1_4_MuzgobInformant"])

    data
    |> Extractor.Transitions.discover()
    |> Narrow.apply(data)
    |> Persister.transitions()

    :ok
  end

  test "MV_SlaveMule: journal entries 105 and 110 are unreachable" do
    assert unreachable_indices("mv_slavemule") == [105, 110]
  end

  test "MV_SlaveMule: 110 is an unreachable entry that nonetheless finishes the quest" do
    entry = journal_entry("mv_slavemule", 110)

    refute entry.reachable
    assert entry.finishes_quest
  end

  test "MV_DeadTaxman: every journal entry is reachable" do
    assert unreachable_indices("mv_deadtaxman") == []
  end

  test "A1_4_MuzgobInformant: every journal entry is reachable" do
    assert unreachable_indices("a1_4_muzgobinformant") == []
  end

  defp unreachable_indices(quest_version_id) do
    JournalEntry
    |> Ash.Query.filter(quest_version_id == ^quest_version_id)
    |> Ash.Query.load(:reachable)
    |> Ash.read!()
    |> Enum.reject(& &1.reachable)
    |> Enum.map(& &1.index)
    |> Enum.sort()
  end

  defp journal_entry(quest_version_id, index) do
    JournalEntry
    |> Ash.Query.filter(quest_version_id == ^quest_version_id and index == ^index)
    |> Ash.Query.load(:reachable)
    |> Ash.read_one!()
  end
end
