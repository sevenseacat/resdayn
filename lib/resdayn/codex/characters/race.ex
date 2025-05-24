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

    create :create do
      primary? true
      accept [
        :id,
        :name,
        :description,
        :playable,
        :beast,
        :male_stats,
        :female_stats,
        :flags
      ]
    end

    create :import do
      description "Custom importer to allow for related skills and spells"
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
        :flags
      ]

      argument :skill_bonuses, {:array, :map}, allow_nil?: false
      argument :special_spell_ids, {:array, :string}, allow_nil?: false

      change Resdayn.Codex.Characters.Changes.SaveRaceRelationships
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
  end

  relationships do
    has_many :skill_bonuses, __MODULE__.SkillBonus

    many_to_many :skills, Resdayn.Codex.Characters.Skill,
      join_relationship: :skill_bonuses

    many_to_many :special_spells, Resdayn.Codex.Mechanics.Spell,
      through: Resdayn.Codex.Characters.Race.SpellBonus
  end
end