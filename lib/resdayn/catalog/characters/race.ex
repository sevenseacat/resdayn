defmodule Resdayn.Catalog.Characters.Race do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.Characters,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable]

  postgres do
    table "races"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, Resdayn.Catalog.Types.RecordId, primary_key?: true, allow_nil?: false

    attribute :name, :string, allow_nil?: false
    attribute :description, :string, allow_nil?: true
    attribute :playable, :boolean, allow_nil?: false
    attribute :beast, :boolean, allow_nil?: false

    attribute :male_stats, __MODULE__.Stats, allow_nil?: false
    attribute :female_stats, __MODULE__.Stats, allow_nil?: false

    attribute :special_spells, {:array, Resdayn.Catalog.Characters.SpellLink},
      allow_nil?: false,
      default: []
  end

  relationships do
    has_many :skill_bonuses, __MODULE__.SkillBonus

    many_to_many :skills, Resdayn.Catalog.Characters.Skill, join_relationship: :skill_bonuses
  end
end
