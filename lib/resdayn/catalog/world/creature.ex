defmodule Resdayn.Catalog.World.Creature do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.World,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable, Resdayn.Catalog.Referencable]

  postgres do
    table "creatures"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, Resdayn.Catalog.Types.RecordId, primary_key?: true, allow_nil?: false
    attribute :name, :string, allow_nil?: false
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

    attribute :attacks, {:array, Resdayn.Catalog.Types.Range},
      allow_nil?: false,
      constraints: [length: 3]

    attribute :attributes, {:array, Resdayn.Catalog.Characters.AttributeValue},
      allow_nil?: false,
      default: []

    attribute :alert, Resdayn.Catalog.World.Alert, allow_nil?: false

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

    attribute :creature_flags, {:array, __MODULE__.Flag}, allow_nil?: false, default: []

    attribute :sound_generator_key, :string
  end

  relationships do
    belongs_to :script, Resdayn.Catalog.Mechanics.Script

    has_many :inventory_items, Resdayn.Catalog.World.InventoryItem,
      destination_attribute: :holder_ref_id

    has_many :sound_generators, Resdayn.Catalog.Assets.SoundGenerator,
      source_attribute: :sound_generator_key,
      destination_attribute: :creature_key

    has_many :quest_involvements, Resdayn.Catalog.QuestAnalysis.ActorInvolvement,
      destination_attribute: :creature_id
  end

  calculations do
    # Display-shaped view of the involvements: distinct quests paired with the
    # roles the creature plays, ordered by importance.
    calculate :related_quests,
              :term,
              {Resdayn.Catalog.QuestAnalysis.QuestsWithRoles, involvements: :quest_involvements}
  end

  aggregates do
    count :related_quest_count, :quest_involvements, field: :quest_id, uniq?: true
  end
end
