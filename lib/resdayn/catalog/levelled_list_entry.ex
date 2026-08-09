defmodule Resdayn.Catalog.LevelledListEntry do
  @moduledoc """
  One entry in a levelled list: an object, and the player level from which it can
  be rolled.

  Shared by both list types. What each will accept differs — see
  `:item_levelled_list_entry` and `:creature_levelled_list_entry` in
  `Resdayn.Catalog.World.ReferencableObject.Type` — but the row is the same shape.
  """

  use Ash.Resource, data_layer: :embedded

  actions do
    defaults [:create, :read, :update, :destroy]
    default_accept [:player_level, :object_ref_id]
  end

  attributes do
    attribute :player_level, :integer, allow_nil?: false, constraints: [min: 0]
  end

  relationships do
    belongs_to :object_ref, Resdayn.Catalog.World.ReferencableObject
  end

  calculations do
    calculate :object, :struct, {Resdayn.Catalog.Calculations.TypedObject, field: :object_ref}
  end
end
