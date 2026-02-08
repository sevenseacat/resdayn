defmodule Resdayn.Importer.Quests.ItemLocations do
  @moduledoc """
  Resolves key locations from quest-critical items (those used in dialogue conditions).

  Items can exist in the world via three paths:
  1. Direct cell references - item placed in a cell
  2. Inventory holders - item inside a container/NPC
  3. Script add_item effects - item added to a container/NPC at runtime

  Only uniquely-placed references (exactly 1 cell reference) are considered
  quest-specific locations.
  """

  defstruct [:unique_placements, :holders]

  @doc """
  Build the index from pre-aggregated data.

  - `unique_placements`: `%{downcased_reference_id => cell_id_string}` - references
    with exactly 1 cell reference
  - `holders`: `%{downcased_item_id => [holder_ref_id_string]}` - items and which
    containers/NPCs hold them
  """
  def build(unique_placements, holders) do
    %__MODULE__{
      unique_placements: unique_placements,
      holders: holders
    }
  end

  @doc """
  Get unique cell locations for a list of condition item IDs.

  `add_item_targets` is a map of `%{downcased_item_id => [target_id_strings]}`
  from script add_item effects, representing items added to containers/NPCs at runtime.
  """
  def get_locations(%__MODULE__{} = index, condition_item_ids, add_item_targets \\ %{}) do
    condition_item_ids
    |> Enum.flat_map(fn item_id ->
      item_id = downcase(item_id)

      direct = [Map.get(index.unique_placements, item_id)]

      via_holders =
        Map.get(index.holders, item_id, [])
        |> Enum.map(fn holder_id -> Map.get(index.unique_placements, downcase(holder_id)) end)

      via_targets =
        Map.get(add_item_targets, item_id, [])
        |> Enum.map(fn target_id -> Map.get(index.unique_placements, downcase(target_id)) end)

      direct ++ via_holders ++ via_targets
    end)
    |> Enum.filter(& &1)
    |> Enum.map(&Ash.CiString.new/1)
    |> Enum.uniq()
  end

  defp downcase(%Ash.CiString{} = value), do: String.downcase(to_string(value))
  defp downcase(value) when is_binary(value), do: String.downcase(value)
end
