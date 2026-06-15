defmodule Resdayn.TransitionTestHelpers do
  @moduledoc """
  Shared lookups for transition extractor tests, which assert against the real
  imported corpus by pinning specific (quest version, index, source) tuples.
  """

  @doc """
  All discovered rows belonging to a quest version.
  """
  def transitions_for(rows, quest_version_id) do
    Enum.filter(rows, &(&1.quest_version_id == quest_version_id))
  end

  @doc """
  Find the single transition row matching all of the provided filters. Raises
  if none / multiple match — the tests pin specific tuples, so anything else
  is a setup error rather than a soft miss.
  """
  def find_transition(rows, filters) do
    matches =
      Enum.filter(rows, fn row ->
        Enum.all?(filters, fn {key, value} ->
          to_string(Map.get(row, key)) == to_string(value)
        end)
      end)

    case matches do
      [row] -> row
      [] -> raise "no transition matched #{inspect(filters)}"
      many -> raise "#{length(many)} transitions matched #{inspect(filters)} — refine filters"
    end
  end
end
