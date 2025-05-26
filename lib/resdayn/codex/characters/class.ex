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

  actions do
    defaults [:read]

    create :import do
      description "Custom importer to allow for related skills"
      upsert? true
      upsert_fields :replace_all

      accept [
        :id,
        :name,
        :description,
        :services_offered,
        :playable,
        :specialization,
        :items_vendored,
        :attribute1_id,
        :attribute2_id,
        :flags
      ]

      argument :major_skill_ids, {:array, :integer}, allow_nil?: false
      argument :minor_skill_ids, {:array, :integer}, allow_nil?: false

      change {Resdayn.Codex.Characters.Changes.UpdateRelationships,
              arguments: [:major_skill_ids, :minor_skill_ids]}
    end

    update :update do
      require_atomic? false

      argument :major_skill_ids, {:array, :integer}, allow_nil?: false
      argument :minor_skill_ids, {:array, :integer}, allow_nil?: false

      change {Resdayn.Codex.Characters.Changes.SaveRelatedSkills, type: :minor}
      change {Resdayn.Codex.Characters.Changes.SaveRelatedSkills, type: :major}
    end
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false

    attribute :name, :string, allow_nil?: false
    attribute :description, :string, allow_nil?: true

    attribute :services_offered, {:array, Resdayn.Codex.Characters.ServicesOffered},
      default: [],
      allow_nil?: false

    attribute :playable, :boolean, allow_nil?: false
    attribute :specialization, Resdayn.Codex.Characters.Specialization, allow_nil?: false

    attribute :items_vendored, {:array, Resdayn.Codex.Characters.ItemsVendored},
      default: [],
      allow_nil?: false,
      description: """
      This doesn't seem to be actually used in the game - more of a guide?

      NPCs have their own set of flags for vendoring different types of items,
      and they don't have to match those of their assigned class

      eg. specific NPCs of class Apothecary Service (flags apparatus,ingredients,
      potions) but their own flags are all false - will not have the option to Barter
      """
  end

  relationships do
    belongs_to :attribute1, Resdayn.Codex.Mechanics.Attribute,
      allow_nil?: false,
      attribute_type: :integer

    belongs_to :attribute2, Resdayn.Codex.Mechanics.Attribute,
      allow_nil?: false,
      attribute_type: :integer

    has_many :major_skill_relationships, __MODULE__.Skill, filter: expr(category == :major)

    many_to_many :major_skills, Resdayn.Codex.Characters.Skill,
      join_relationship: :major_skill_relationships

    has_many :minor_skill_relationships, __MODULE__.Skill, filter: expr(category == :minor)

    many_to_many :minor_skills, Resdayn.Codex.Characters.Skill,
      join_relationship: :minor_skill_relationships
  end

  aggregates do
    list :major_skill_ids, :major_skills, :id
    list :minor_skill_ids, :minor_skills, :id
  end
end
