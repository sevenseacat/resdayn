defmodule Resdayn.QuestAnalyzer.Extractor.Transitions.Preconditions.Narrow do
  @moduledoc """
  Tighten transition `from_min`/`from_max` ranges using each quest version's
  known journal-entry indices.

  A transition's source condition gives a continuous bound (e.g. `journal < 20`
  → `from_max: 19`), but a quest's journal only ever holds a discrete set of
  indices. Restricting the recovered range to the indices that actually exist
  often collapses an open range to a single state:

  - exactly one known index in `[from_min, from_max]` → pin both bounds to it
  - no known index in range → the only state it can fire from is the unstarted
    quest, so pin to `{0, 0}`
  - many known indices → genuinely ambiguous, leave the range untouched

  Only rows with a concrete `from_max` are narrowed; without an upper bound
  there's no finite range to inspect. A missing `from_min` is treated as `0`
  (the unstarted quest) while searching, but is only written back when the
  range resolves to a pin or a start — an ambiguous range keeps the nil.

  This is one layer in the precondition chain: it runs over discovered rows
  and returns the updated list, so it composes with the other fallback layers.
  """

  alias Resdayn.QuestAnalyzer.LoadedData

  def apply(rows, %LoadedData{} = data) do
    rows
    |> Enum.map(&narrow(&1, known_indices(&1, data)))
    |> Enum.uniq()
  end

  defp known_indices(row, data) do
    case LoadedData.fetch_quest_version(data, row.quest_version_id) do
      {:ok, qv} -> MapSet.new(qv.journal_entries, & &1.index)
      :error -> MapSet.new()
    end
  end

  defp narrow(%{from_max: nil} = row, _known_indices), do: row

  defp narrow(%{from_max: from_max} = row, known_indices) do
    search_min = row.from_min || 0

    in_range =
      known_indices
      |> Enum.filter(&(&1 >= search_min and &1 <= from_max))

    case in_range do
      [] -> %{row | from_min: 0, from_max: 0}
      [single] -> %{row | from_min: single, from_max: single}
      _ -> row
    end
  end
end
