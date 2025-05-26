defmodule Resdayn.Codex.World.InventoryItem.Item do
  use Ash.Resource.Calculation

  @types [
    :tool,
    :clothing,
    :weapon,
    :armor,
    :book,
    :ingredient,
    :potion,
    :light,
    :alchemy_apparatus,
    :miscellaneous_item
  ]

  @impl true
  def load(_, _, _), do: @types

  @impl true
  def calculate(records, _opts, _contet) do
    Enum.map(records, fn record ->
      Map.take(record, @types)
      |> Map.values()
      |> Enum.find(& &1)
    end)
  end
end
