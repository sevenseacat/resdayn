defmodule Resdayn.Codex.World.NPC do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.World,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable, Resdayn.Codex.Referencable]

  postgres do
    table "npcs"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false
    attribute :name, :string
    attribute :level, :integer, allow_nil?: false, constraints: [min: 0]

    attribute :head_model_id, :string, allow_nil?: false
    attribute :hair_model_id, :string, allow_nil?: false

    attribute :disposition, :integer, allow_nil?: false, constraints: [min: 0]
    attribute :global_reputation, :integer, allow_nil?: false, constraints: [min: 0]

    attribute :faction_rank, :integer, constraints: [min: 0, max: 10]
    attribute :gold, :integer, allow_nil?: false, constraints: [min: 0]

    attribute :health, :integer, constraints: [min: 0]
    attribute :magicka, :integer, constraints: [min: 0]
    attribute :fatigue, :integer, constraints: [min: 0]

    attribute :attributes, {:array, Resdayn.Codex.Characters.AttributeValue},
      allow_nil?: false,
      default: []

    attribute :alert, Resdayn.Codex.World.Alert, allow_nil?: false
    attribute :blood, __MODULE__.BloodType, allow_nil?: false

    attribute :spell_links, {:array, Resdayn.Codex.Characters.SpellLink},
      allow_nil?: false,
      default: []

    attribute :services_offered, {:array, Resdayn.Codex.Characters.ServicesOffered},
      default: [],
      allow_nil?: false

    attribute :items_vendored, {:array, Resdayn.Codex.Characters.ItemsVendored},
      default: [],
      allow_nil?: false

    attribute :transport_options, {:array, Resdayn.Codex.World.TransportDestination}

    attribute :ai_packages, {:array, :map}, default: []

    attribute :npc_flags, {:array, __MODULE__.Flag}, allow_nil?: false, default: []
  end

  relationships do
    belongs_to :script, Resdayn.Codex.Mechanics.Script
    belongs_to :race, Resdayn.Codex.Characters.Race, allow_nil?: false
    belongs_to :class, Resdayn.Codex.Characters.Class, allow_nil?: false
    belongs_to :faction, Resdayn.Codex.Characters.Faction

    has_many :skill_values, __MODULE__.SkillValue do
      sort :skill_id
    end

    many_to_many :skills, Resdayn.Codex.Characters.Skill, join_relationship: :skill_values

    has_many :trained_skill_values, __MODULE__.SkillValue do
      filter expr(:training in npc.services_offered)
      sort value: :desc, skill_id: :asc
      limit 3
    end

    many_to_many :trained_skills, Resdayn.Codex.Characters.Skill do
      join_relationship :trained_skill_values
    end

    has_many :inventory_items, Resdayn.Codex.World.InventoryItem,
      destination_attribute: :holder_ref_id

    has_many :cell_references, Resdayn.Codex.World.Cell.CellReference,
      destination_attribute: :reference_id
  end

  calculations do
    calculate :gender, :atom, expr(if :female in npc_flags, do: :female, else: :male)
    calculate :essential?, :boolean, expr(:essential in npc_flags)
  end

  aggregates do
    first :cell_name, [:cell_references, :cell], :name
  end
end
