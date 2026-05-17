defmodule Resdayn.Codex.QuestAnalysis.RelatedItem do
  use Ash.TypedStruct

  typed_struct do
    field :item_id, :ci_string, allow_nil?: false

    # Each use is a discrete event at a specific transition.
    # The same item can have multiple uses on the same transition (e.g. the
    # ring is both :required and :surrendered at Thavere's Journal 90 response).
    field :uses, {:array, :struct} do
      constraints fields: [
                    role: [
                      type: :atom,
                      allow_nil?: false,
                      constraints: [one_of: [:required, :received, :surrendered]]
                    ],
                    transition_id: [type: :string, allow_nil?: false]
                  ]

      default []
    end
  end
end
