defmodule Resdayn.Codex.Items.ItemLevelledList.Item do
  use Ash.Resource, data_layer: :embedded

  actions do
    defaults [:create, :read, :update, :destroy]
    default_accept [:player_level, :item_ref_id]
  end

  attributes do
    attribute :player_level, :integer, allow_nil?: false, constraints: [min: 0]
  end

  relationships do
    belongs_to :item_ref, Resdayn.Codex.World.ReferencableObject
  end

  calculations do
    calculate :item, :struct, {Resdayn.Codex.Calculations.TypedObject, field: :item_ref}
  end
end
