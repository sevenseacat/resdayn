defmodule Resdayn.Codex.World.Creature do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.World,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable, Resdayn.Codex.Referencable]

  postgres do
    table "creatures"
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
    attribute :type, __MODULE__.Type, allow_nil?: false

    attribute :nif_model_filename, :string, allow_nil?: false
    attribute :level, :integer, allow_nil?: false, constraints: [min: 0]
    attribute :gold, :integer, allow_nil?: false, constraints: [min: 0]
    attribute :scale, :float, default: 1
    attribute :soul_size, :integer, allow_nil?: false, constraints: [min: 0]

    attribute :health, :integer, constraints: [min: 0]
    attribute :magicka, :integer, constraints: [min: 0]
    attribute :fatigue, :integer, constraints: [min: 0]

    attribute :combat, :integer, constraints: [min: 0]
    attribute :magic, :integer, constraints: [min: 0]
    attribute :stealth, :integer, constraints: [min: 0]

    attribute :attacks, {:array, :range}, allow_nil?: false, constraints: [length: 3]

    attribute :attributes, {:array, Resdayn.Codex.Characters.AttributeValue},
      allow_nil?: false,
      default: []

    attribute :alert, Resdayn.Codex.World.Alert, allow_nil?: false

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

    attribute :creature_flags, {:array, __MODULE__.Flag}, allow_nil?: false, default: []

    attribute :sound_generator_key, :string
  end

  relationships do
    belongs_to :script, Resdayn.Codex.Mechanics.Script

    has_many :inventory_items, Resdayn.Codex.World.InventoryItem,
      destination_attribute: :holder_ref_id

    has_many :sound_generators, Resdayn.Codex.Assets.SoundGenerator,
      source_attribute: :sound_generator_key,
      destination_attribute: :creature_key
  end
end
