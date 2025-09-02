defmodule Resdayn.Codex.Characters.Race.SkillBonus do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Characters,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "race_skill_bonuses"
    repo Resdayn.Repo

    references do
      reference :race, on_delete: :delete
      reference :skill, on_delete: :delete
    end
  end

  actions do
    default_accept [:bonus, :race_id, :skill_id]
    defaults [:read, :create, :update, :destroy]
  end

  attributes do
    attribute :bonus, :integer, allow_nil?: false, public?: true
  end

  relationships do
    belongs_to :race, Resdayn.Codex.Characters.Race,
      primary_key?: true,
      allow_nil?: false,
      attribute_type: :string

    belongs_to :skill, Resdayn.Codex.Characters.Skill,
      primary_key?: true,
      allow_nil?: false,
      attribute_type: :integer
  end
end
