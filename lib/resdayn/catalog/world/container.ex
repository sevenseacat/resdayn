defmodule Resdayn.Catalog.World.Container do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.World,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable, Resdayn.Catalog.Referencable]

  postgres do
    table "containers"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, Resdayn.Catalog.Types.RecordId, primary_key?: true, allow_nil?: false
    attribute :name, :string
    attribute :nif_model_filename, :string, allow_nil?: false
    attribute :capacity, :float, allow_nil?: false, constraints: [min: 0]

    attribute :container_flags, {:array, __MODULE__.Flag},
      allow_nil?: false,
      default: []
  end

  relationships do
    belongs_to :script, Resdayn.Catalog.Mechanics.Script

    has_many :items_contained, Resdayn.Catalog.World.InventoryItem,
      destination_attribute: :holder_ref_id
  end
end
