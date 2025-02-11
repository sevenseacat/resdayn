defmodule Resdayn.Codex.Characters.Class do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Characters,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "classes"
    repo Resdayn.Repo
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false

    attribute :name, :string, allow_nil?: false
    attribute :description, :string, allow_nil?: true

    attribute :services_offered, {:array, __MODULE__.ServicesOffered},
      default: [],
      allow_nil?: false

    attribute :playable, :boolean, allow_nil?: false
    attribute :specialization, Resdayn.Codex.Characters.Specialization, allow_nil?: false
    attribute :items_vendored, {:array, __MODULE__.ItemsVendored}, default: [], allow_nil?: false
  end

  relationships do
    belongs_to :attribute1, Resdayn.Codex.Mechanics.Attribute,
      allow_nil?: false,
      attribute_type: :integer

    belongs_to :attribute2, Resdayn.Codex.Mechanics.Attribute,
      allow_nil?: false,
      attribute_type: :integer

    has_many :major_skill_relationships, Resdayn.Codex.Characters.ClassSkill,
      filter: expr(category == :major)

    many_to_many :major_skills, Resdayn.Codex.Characters.Skill,
      join_relationship: :major_skill_relationships

    has_many :minor_skill_relationships, Resdayn.Codex.Characters.ClassSkill,
      filter: expr(category == :minor)

    many_to_many :minor_skills, Resdayn.Codex.Characters.Skill,
      join_relationship: :minor_skill_relationships
  end
end
