defmodule Resdayn.Catalog.Characters.Race.SkillBonus do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.Characters,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable]

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
    attribute :bonus, :integer, allow_nil?: false, public?: true, constraints: [min: 0]
  end

  relationships do
    belongs_to :race, Resdayn.Catalog.Characters.Race,
      primary_key?: true,
      allow_nil?: false

    belongs_to :skill, Resdayn.Catalog.Characters.Skill,
      primary_key?: true,
      allow_nil?: false,
      attribute_type: :integer
  end
end
