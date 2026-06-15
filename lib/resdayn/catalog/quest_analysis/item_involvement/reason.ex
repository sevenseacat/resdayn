defmodule Resdayn.Catalog.QuestAnalysis.ItemInvolvement.Reason do
  use Ash.Type.Enum,
    values: [
      required: [label: "Required"],
      surrendered: [label: "Surrendered"],
      received: [label: "Received"],
      placed: [label: "Placed"],
      item_mention: [label: "Mention"]
    ]

  @ordered_by_importance [
    :required,
    :surrendered,
    :received,
    :placed,
    :item_mention
  ]

  @doc """
  Reasons ranked from most-central to most-peripheral involvement. Used to
  choose an item's primary role and to order its roles for display.

  Ordering rationale: `:required` is the strongest signal (the quest gates
  progress on it). `:surrendered` and `:received` are concrete inventory
  transactions and tightly bound to quest steps. `:placed` is usually
  flavour (the item is set-dressing somewhere in the world).
  `:item_mention` is the catch-all for soft signals.
  """
  def by_importance, do: @ordered_by_importance

  @doc "Rank of a reason, lower being more central. Sortable."
  def importance(reason), do: Enum.find_index(@ordered_by_importance, &(&1 == reason))
end
