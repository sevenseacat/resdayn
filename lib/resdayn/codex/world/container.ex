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
