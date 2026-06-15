defmodule Resdayn.Catalog.World.Cell.CellReference do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.World,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable]

  postgres do
    table "cell_references"
    repo Resdayn.Repo

    references do
      reference :cell, index?: true, on_delete: :delete
      reference :reference, index?: true
    end
  end

  actions do
    defaults [:read, :create, :update, :destroy]

    default_accept [
      :cell_id,
      :reference_id,
      :id,
      :coordinates,
      :count,
      :scale,
      :transport_to,
      :usage_remaining,
      :lock_difficulty,
      :required_faction_rank,
      :enchantment_charge,
      :blocked,
      :owner_id,
      :owner_faction_id,
      :key_id,
      :trap_id,
      :soul_id,
      :global_variable_id
    ]
  end

  attributes do
    attribute :id, :integer, primary_key?: true, allow_nil?: false
    attribute :count, :integer, constraints: [min: 1]
    attribute :scale, :float, default: 1.0
    attribute :coordinates, Resdayn.Catalog.Types.Coordinates, allow_nil?: false

    attribute :transport_to, Resdayn.Catalog.World.TransportDestination
    attribute :usage_remaining, Resdayn.Catalog.Types.Number
    attribute :lock_difficulty, :integer, constraints: [min: 0]
    attribute :required_faction_rank, :integer, constraints: [min: 0]
    attribute :enchantment_charge, :float, constraints: [min: 0.0]
    attribute :blocked, :boolean, default: false
  end

  relationships do
    belongs_to :cell, Resdayn.Catalog.World.Cell,
      allow_nil?: false,
      primary_key?: true

    belongs_to :reference, Resdayn.Catalog.World.ReferencableObject, allow_nil?: false

    belongs_to :owner, Resdayn.Catalog.World.NPC
    belongs_to :owner_faction, Resdayn.Catalog.Characters.Faction

    belongs_to :key, Resdayn.Catalog.World.ReferencableObject
    belongs_to :trap, Resdayn.Catalog.Mechanics.Spell
    belongs_to :soul, Resdayn.Catalog.World.Creature
    belongs_to :global_variable, Resdayn.Catalog.Mechanics.GlobalVariable
  end
end
