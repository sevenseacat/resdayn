defmodule Resdayn.Codex.World.CreatureLevelledList.Creature do
  use Ash.Resource, data_layer: :embedded

  actions do
    defaults [:create, :read, :update, :destroy]
    default_accept [:player_level, :creature_ref_id]
  end

  attributes do
    attribute :player_level, :integer, allow_nil?: false, constraints: [min: 0]
  end

  relationships do
    belongs_to :creature_ref, Resdayn.Codex.World.ReferencableObject
  end

  calculations do
    calculate :creature, :struct, {Resdayn.Codex.Calculations.TypedObject, field: :creature_ref}
  end
end
