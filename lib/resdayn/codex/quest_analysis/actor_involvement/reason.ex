defmodule Resdayn.Codex.QuestAnalysis.ActorInvolvement.Reason do
  use Ash.Type.Enum,
    values: [
      dialogue_speaker: [label: "Dialogue Speaker"],
      script_bearer: [label: "Script Bearer"],
      effect_target: [label: "Effect Target"],
      effect_mention: [label: "Effect Mention"]
    ]
end
