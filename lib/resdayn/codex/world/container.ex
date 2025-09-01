defmodule Resdayn.Codex.World.Container do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.World,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable, Resdayn.Codex.Referencable]

  postgres do
    table "containers"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]

    update :import_relationships do
      require_atomic? false
      argument :inventory, {:array, :map}, allow_nil?: false, default: []

      change {Resdayn.Codex.Changes.OptimizedRelationshipImport,
              argument: :inventory,
              relationship: :items_contained,
              related_resource: Resdayn.Codex.World.InventoryItem,
              parent_key: :holder_ref_id,
              id_field: :object_ref_id,
              on_missing: :destroy}
    end
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false
    attribute :name, :string
    attribute :nif_model_filename, :string
    attribute :capacity, :float, allow_nil?: false, constraints: [min: 0]

    attribute :container_flags, {:array, __MODULE__.Flag},
      allow_nil?: false,
      default: []
  end

  relationships do
    belongs_to :script, Resdayn.Codex.Mechanics.Script

    has_many :items_contained, Resdayn.Codex.World.InventoryItem,
      destination_attribute: :holder_ref_id
  end
end
