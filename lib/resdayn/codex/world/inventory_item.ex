defmodule Resdayn.Codex.World.InventoryItem do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.World,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "inventory_items"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read, :create, :update, :destroy]
    default_accept [:count, :restocking?, :holder_ref_id, :object_ref_id]
  end

  attributes do
    attribute :count, :integer, allow_nil?: false, constraints: [min: 1], default: 1
    attribute :restocking?, :boolean, allow_nil?: false, default: false
  end

  relationships do
    belongs_to :holder_ref, Resdayn.Codex.World.ReferencableObject,
      attribute_type: :string,
      allow_nil?: false,
      primary_key?: true

    belongs_to :object_ref, Resdayn.Codex.World.ReferencableObject,
      attribute_type: :string,
      allow_nil?: false,
      primary_key?: true
  end

  calculations do
    calculate :holder, :struct, {Resdayn.Codex.Calculations.TypedObject, field: :holder_ref}
    calculate :object, :struct, {Resdayn.Codex.Calculations.TypedObject, field: :object_ref}
  end
end
