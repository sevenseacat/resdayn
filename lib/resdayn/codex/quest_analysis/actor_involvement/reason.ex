defmodule Resdayn.Codex.QuestAnalysis.ActorInvolvement.Reason do
  use Ash.Type.Enum,
    values: [
      dialogue_speaker: [label: "Dialogue Speaker"],
      script_bearer: [label: "Script Bearer"],
      effect_target: [label: "Effect Target"],
      effect_mention: [label: "Effect Mention"]
    ]

  @ordered_by_importance [
    :dialogue_speaker,
    :script_bearer,
    :effect_target,
    :effect_mention
  ]

  @doc """
  Reasons ranked from most-central to most-peripheral involvement. Used to
  choose an actor's primary role and to order their roles for display.
  """
  def by_importance, do: @ordered_by_importance

  @doc "Rank of a reason, lower being more central. Sortable."
  def importance(reason), do: Enum.find_index(@ordered_by_importance, &(&1 == reason))
end
