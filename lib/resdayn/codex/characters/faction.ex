defmodule Resdayn.Codex.Characters.Faction do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Characters,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "factions"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]

    update :import_relationships do
      require_atomic? false

      argument :skill_ids, {:array, :integer}, default: [], allow_nil?: false
      argument :reactions, {:array, :map}, default: [], allow_nil?: false

      change manage_relationship(:skill_ids, :favored_skills, type: :append_and_remove)
      change manage_relationship(:reactions, type: :direct_control)
    end
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false

    attribute :name, :string, allow_nil?: false
    attribute :ranks, {:array, __MODULE__.Rank}, default: [], allow_nil?: false

    attribute :hidden, :boolean, default: false, allow_nil?: false
  end

  relationships do
    belongs_to :attribute1, Resdayn.Codex.Mechanics.Attribute,
      allow_nil?: false,
      attribute_type: :integer

    belongs_to :attribute2, Resdayn.Codex.Mechanics.Attribute,
      allow_nil?: false,
      attribute_type: :integer

    has_many :favored_skill_relationships, __MODULE__.Skill

    many_to_many :favored_skills, Resdayn.Codex.Characters.Skill,
      join_relationship: :favored_skill_relationships

    has_many :reactions, __MODULE__.Reaction, destination_attribute: :source_id
    has_many :reactions_from, __MODULE__.Reaction, destination_attribute: :target_id
  end
end
