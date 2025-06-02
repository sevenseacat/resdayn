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

    update :import_relationships do
      require_atomic? false
      argument :inventory, {:array, :map}, allow_nil?: false, default: []

      change {Resdayn.Codex.Changes.OptimizedRelationshipImport,
              argument: :inventory,
              relationship: :inventory_items,
              related_resource: Resdayn.Codex.World.InventoryItem,
              parent_key: :holder_ref_id,
              id_field: :object_ref_id,
              on_missing: :destroy}
    end
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

    attribute :skills, {:array, Resdayn.Codex.Characters.SkillValue},
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

    has_many :inventory_items, Resdayn.Codex.World.InventoryItem,
      destination_attribute: :holder_ref_id

    has_many :cell_references, Resdayn.Codex.World.Cell.CellReference,
      destination_attribute: :reference_id
  end
end
