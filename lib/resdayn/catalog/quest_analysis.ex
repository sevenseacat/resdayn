defmodule Resdayn.Catalog.QuestAnalysis do
  use Ash.Domain,
    otp_app: :resdayn

  resources do
    resource Resdayn.Catalog.QuestAnalysis.ActorInvolvement
    resource Resdayn.Catalog.QuestAnalysis.ItemInvolvement
    resource Resdayn.Catalog.QuestAnalysis.Transition
  end
end
