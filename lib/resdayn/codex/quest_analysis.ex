defmodule Resdayn.Codex.QuestAnalysis do
  use Ash.Domain,
    otp_app: :resdayn

  resources do
    resource Resdayn.Codex.QuestAnalysis.NPCInvolvement
  end
end
