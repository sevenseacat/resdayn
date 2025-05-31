defmodule Resdayn.Codex.World.Cell.CellReference do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.World,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "cell_references"
    repo Resdayn.Repo

    references do
      reference :cell, index?: true, on_delete: :delete
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
    attribute :coordinates, :coordinates, allow_nil?: false

    attribute :transport_to, Resdayn.Codex.World.TransportDestination
    attribute :usage_remaining, :number
    attribute :lock_difficulty, :integer, constraints: [min: 0]
    attribute :required_faction_rank, :integer, constraints: [min: 0]
    attribute :enchantment_charge, :float, constraints: [min: 0.0]
    attribute :blocked, :boolean, default: false
  end

  relationships do
    belongs_to :cell, Resdayn.Codex.World.Cell,
      allow_nil?: false,
      attribute_type: :string,
      primary_key?: true

    belongs_to :reference, Resdayn.Codex.World.ReferencableObject,
      attribute_type: :string,
      allow_nil?: false

    belongs_to :owner, Resdayn.Codex.World.NPC
    belongs_to :owner_faction, Resdayn.Codex.Characters.Faction

    belongs_to :key, Resdayn.Codex.World.ReferencableObject
    belongs_to :trap, Resdayn.Codex.Mechanics.Spell
    belongs_to :soul, Resdayn.Codex.World.Creature
    belongs_to :global_variable, Resdayn.Codex.Mechanics.GlobalVariable
  end
end
