defmodule Resdayn.Codex.QuestAnalysis.RelatedNPC do
  use Ash.TypedStruct

  typed_struct do
    field :npc_id, :ci_string, allow_nil?: false

    field :reason, :atom do
      constraints one_of: [:dialogue_speaker, :script_bearer, :effect_target]
      allow_nil? false
    end

    field :quest_giver?, :boolean, default: false
    field :quest_finisher?, :boolean, default: false

    # Per-transition involvement. :trigger means this NPC fires the transition
    # (as dialogue speaker or script bearer). :effect_target means they're a
    # subject of an effect at the transition.
    field :uses, {:array, :struct} do
      constraints fields: [
                    role: [
                      type: :atom,
                      allow_nil?: false,
                      constraints: [one_of: [:trigger, :effect_target]]
                    ],
                    transition_id: [type: :string, allow_nil?: false]
                  ]

      default []
    end
  end
end
