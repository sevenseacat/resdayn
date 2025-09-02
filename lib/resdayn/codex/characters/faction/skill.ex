defmodule Resdayn.Codex.Characters.Faction.Skill do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Characters,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "faction_skills"
    repo Resdayn.Repo
  end

  actions do
    defaults [:create, :read, :update, :destroy]
    default_accept [:faction_id, :skill_id]
  end

  relationships do
    belongs_to :faction, Resdayn.Codex.Characters.Faction,
      primary_key?: true,
      allow_nil?: false,
      attribute_type: :string

    belongs_to :skill, Resdayn.Codex.Characters.Skill,
      primary_key?: true,
      allow_nil?: false,
      attribute_type: :integer
  end
end
