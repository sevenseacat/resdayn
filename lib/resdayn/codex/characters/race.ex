defmodule Resdayn.Codex.Characters.Race do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Characters,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "races"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]

    create :import do
      description "Custom importer to allow for related skill bonuses"
      upsert? true
      upsert_fields :replace_all

      accept [
        :id,
        :name,
        :description,
        :playable,
        :beast,
        :male_stats,
        :female_stats,
        :special_spells,
        :flags
      ]

      argument :skill_bonuses, {:array, :map}, allow_nil?: false

      change {Resdayn.Codex.Characters.Changes.UpdateRelationships, arguments: [:skill_bonuses]}
    end

    update :update do
      require_atomic? false
      argument :skill_bonuses, {:array, :map}, allow_nil?: false

      change Resdayn.Codex.Characters.Changes.SaveRaceSkills
    end
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false

    attribute :name, :string, allow_nil?: false
    attribute :description, :string, allow_nil?: true
    attribute :playable, :boolean, allow_nil?: false
    attribute :beast, :boolean, allow_nil?: false

    attribute :male_stats, __MODULE__.Stats,
      allow_nil?: false,
      public?: true

    attribute :female_stats, __MODULE__.Stats,
      allow_nil?: false,
      public?: true

    attribute :special_spells, {:array, __MODULE__.SpellBonus},
      allow_nil?: false,
      default: [],
      public?: true
  end

  relationships do
    has_many :skill_bonuses, __MODULE__.SkillBonus

    many_to_many :skills, Resdayn.Codex.Characters.Skill, join_relationship: :skill_bonuses
  end
end
