defmodule Resdayn.Codex.Characters.ClassSkill do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Characters,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "class_skills"
    repo Resdayn.Repo
  end

  attributes do
    attribute :category, :atom, constraints: [one_of: [:major, :minor]], allow_nil?: false
  end

  relationships do
    belongs_to :class, Resdayn.Codex.Characters.Class,
      primary_key?: true,
      allow_nil?: false,
      attribute_writable?: true,
      attribute_type: :string

    belongs_to :skill, Resdayn.Codex.Characters.Skill,
      primary_key?: true,
      allow_nil?: false,
      attribute_writable?: true,
      attribute_type: :integer
  end
end
