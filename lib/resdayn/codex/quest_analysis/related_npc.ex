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
  end
end
