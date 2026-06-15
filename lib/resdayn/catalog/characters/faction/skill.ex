defmodule Resdayn.Catalog.Characters.Faction.Skill do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.Characters,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable]

  postgres do
    table "faction_skills"
    repo Resdayn.Repo
  end

  actions do
    defaults [:create, :read, :update, :destroy]
    default_accept [:faction_id, :skill_id]
  end

  relationships do
    belongs_to :faction, Resdayn.Catalog.Characters.Faction,
      primary_key?: true,
      allow_nil?: false

    belongs_to :skill, Resdayn.Catalog.Characters.Skill,
      primary_key?: true,
      allow_nil?: false,
      attribute_type: :integer
  end
end
