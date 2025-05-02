defmodule Resdayn.Codex.Characters.ClassSkill do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Characters,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "class_skills"
    repo Resdayn.Repo
  end

  actions do
    defaults [:create, :read, :update, :destroy]
    default_accept [:class_id, :category, :skill_id]

    create :import do
      upsert? true
    end
  end

  attributes do
    attribute :category, :atom, constraints: [one_of: [:major, :minor]], allow_nil?: false
  end

  relationships do
    belongs_to :class, Resdayn.Codex.Characters.Class,
      primary_key?: true,
      allow_nil?: false,
      attribute_type: :string

    belongs_to :skill, Resdayn.Codex.Characters.Skill,
      primary_key?: true,
      allow_nil?: false,
      attribute_type: :integer
  end
end
