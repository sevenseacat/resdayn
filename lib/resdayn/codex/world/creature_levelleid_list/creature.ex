defmodule Resdayn.Codex.World.CreatureLevelledList.Creature do
  use Ash.Resource, data_layer: :embedded

  actions do
    defaults [:create, :read, :update, :destroy]
    default_accept [:player_level, :creature_id]
  end

  attributes do
    attribute :player_level, :integer, allow_nil?: false, constraints: [min: 0]
  end

  relationships do
    belongs_to :creature, Resdayn.Codex.World.Creature
  end
end
