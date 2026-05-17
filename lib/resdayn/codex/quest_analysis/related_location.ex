defmodule Resdayn.Codex.QuestAnalysis.RelatedLocation do
  use Ash.TypedStruct

  typed_struct do
    field :cell_id, :ci_string, allow_nil?: false

    field :npc_ids, {:array, :ci_string}, default: []
    field :item_ids, {:array, :ci_string}, default: []

    # Transitions occurring at this cell, derived from the transitions
    # involving any NPC or item at this location.
    field :transition_ids, {:array, :string}, default: []
  end
end
