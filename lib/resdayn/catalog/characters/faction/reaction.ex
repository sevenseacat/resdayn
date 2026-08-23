defmodule Resdayn.Catalog.Characters.Faction.Reaction do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.Characters,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable]

  postgres do
    table "faction_reactions"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :adjustment, :integer, allow_nil?: false, default: 0
  end

  relationships do
    belongs_to :source, Resdayn.Catalog.Characters.Faction,
      allow_nil?: false,
      primary_key?: true

    belongs_to :target, Resdayn.Catalog.Characters.Faction,
      allow_nil?: false,
      primary_key?: true
  end
end
