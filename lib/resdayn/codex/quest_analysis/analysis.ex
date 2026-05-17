defmodule Resdayn.Codex.QuestAnalysis.Analysis do
  use Ash.TypedStruct

  typed_struct do
    field :quest_id, :ci_string, allow_nil?: false

    field :journal_entries, {:array, :struct} do
      constraints fields: [
                    index: [type: :integer, allow_nil?: false],
                    content: [type: :string, allow_nil?: false],
                    finish?: [type: :boolean, allow_nil?: false],
                    restart?: [type: :boolean, allow_nil?: false]
                  ]

      default []
    end

    field :transitions, {:array, Resdayn.Codex.QuestAnalysis.Transition}, default: []

    field :related_items, {:array, Resdayn.Codex.QuestAnalysis.RelatedItem}, default: []

    field :related_npcs, {:array, Resdayn.Codex.QuestAnalysis.RelatedNPC}, default: []

    field :related_locations, {:array, Resdayn.Codex.QuestAnalysis.RelatedLocation}, default: []

    field :dialogue_topics, {:array, :ci_string}, default: []
  end
end
