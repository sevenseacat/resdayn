defmodule Resdayn.Codex.Characters.Faction.Reaction do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Characters,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "faction_reactions"
    repo Resdayn.Repo

    references do
      reference :target, deferrable: :initially
    end
  end

  actions do
    defaults [:read, :create, :update, :destroy]
    default_accept [:adjustment, :target_id]
  end

  attributes do
    attribute :adjustment, :integer, allow_nil?: false, default: 0
  end

  relationships do
    belongs_to :source, Resdayn.Codex.Characters.Faction,
      allow_nil?: false,
      attribute_type: :string,
      primary_key?: true,
      public?: true

    belongs_to :target, Resdayn.Codex.Characters.Faction,
      allow_nil?: false,
      attribute_type: :string,
      primary_key?: true,
      public?: true
  end
end
