defmodule Resdayn.Codex.World.ReferencableObject do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.World,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "referencable_objects"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read, :update, :destroy]

    create :create do
      accept [:id, :type]
    end
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false, public?: true
    attribute :type, __MODULE__.Type, allow_nil?: false, public?: true
  end

  relationships do
    has_many :inventory_items, Resdayn.Codex.World.InventoryItem,
      destination_attribute: :object_ref_id
  end

  identities do
    identity :unique_id_type, [:id, :type]
  end
end
