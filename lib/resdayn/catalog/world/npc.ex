defmodule Resdayn.Catalog.World.NPC do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.World,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable, Resdayn.Catalog.Referencable]

  postgres do
    table "npcs"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, Resdayn.Catalog.Types.RecordId, primary_key?: true, allow_nil?: false
    attribute :name, :string, allow_nil?: false
    attribute :level, :integer, allow_nil?: false, constraints: [min: 0, max: 65_535]

    attribute :head_model_id, :string, allow_nil?: false
    attribute :hair_model_id, :string, allow_nil?: false

    attribute :disposition, :integer, allow_nil?: false, constraints: [min: 0, max: 255]
    attribute :global_reputation, :integer, allow_nil?: false, constraints: [min: 0, max: 255]

    attribute :faction_rank, :integer, constraints: [min: 0, max: 10]
    attribute :gold, :integer, allow_nil?: false, constraints: [min: 0]

    attribute :health, :integer, constraints: [min: 0, max: 65_535]
    attribute :magicka, :integer, constraints: [min: 0, max: 65_535]
    attribute :fatigue, :integer, constraints: [min: 0, max: 65_535]

    attribute :attributes, {:array, Resdayn.Catalog.Characters.AttributeValue},
      allow_nil?: false,
      default: []

    attribute :alert, Resdayn.Catalog.World.Alert, allow_nil?: false
    attribute :blood, __MODULE__.BloodType, allow_nil?: false

    attribute :spell_links, {:array, Resdayn.Catalog.Characters.SpellLink},
      allow_nil?: false,
      default: []

    attribute :services_offered, {:array, Resdayn.Catalog.Characters.ServicesOffered},
      default: [],
      allow_nil?: false

    attribute :items_vendored, {:array, Resdayn.Catalog.Characters.ItemsVendored},
      default: [],
      allow_nil?: false

    attribute :transport_options, {:array, Resdayn.Catalog.World.TransportDestination}

    attribute :ai_packages, {:array, :map}, default: []

    attribute :npc_flags, {:array, __MODULE__.Flag}, allow_nil?: false, default: []
  end

  relationships do
    belongs_to :script, Resdayn.Catalog.Mechanics.Script
    belongs_to :race, Resdayn.Catalog.Characters.Race, allow_nil?: false
    belongs_to :class, Resdayn.Catalog.Characters.Class, allow_nil?: false
    belongs_to :faction, Resdayn.Catalog.Characters.Faction

    has_many :skill_values, __MODULE__.SkillValue do
      sort :skill_id
    end

    many_to_many :skills, Resdayn.Catalog.Characters.Skill, join_relationship: :skill_values

    has_many :trained_skill_values, __MODULE__.SkillValue do
      filter expr(:training in npc.services_offered)
      sort value: :desc, skill_id: :asc
      limit 3
    end

    many_to_many :trained_skills, Resdayn.Catalog.Characters.Skill do
      join_relationship :trained_skill_values
    end

    has_many :inventory_items, Resdayn.Catalog.World.InventoryItem,
      destination_attribute: :holder_ref_id

    has_many :cell_references, Resdayn.Catalog.World.Cell.CellReference,
      destination_attribute: :reference_id

    has_one :cell, Resdayn.Catalog.World.Cell do
      no_attributes? true
      filter expr(id == parent(cell_id))
    end

    has_many :quest_involvements, Resdayn.Catalog.QuestAnalysis.ActorInvolvement,
      destination_attribute: :npc_id
  end

  calculations do
    calculate :gender, :atom, expr(if :female in npc_flags, do: :female, else: :male)
    calculate :essential?, :boolean, expr(:essential in npc_flags)

    # Display-shaped view of the involvements: distinct quests paired with the
    # roles the NPC plays, ordered by importance.
    calculate :related_quests,
              :term,
              {Resdayn.Catalog.QuestAnalysis.QuestsWithRoles, involvements: :quest_involvements}
  end

  aggregates do
    first :cell_id, :cell_references, :cell_id
    first :cell_name, [:cell_references, :cell], :name
    count :related_quest_count, :quest_involvements, field: :quest_id, uniq?: true

    # The skill ids an NPC can train — the top 3 (see `trained_skill_values`).
    # The relationship's limit is honored here since ash_sql 0.6.6.
    list :trained_skill_ids, :trained_skill_values, :skill_id
  end
end
