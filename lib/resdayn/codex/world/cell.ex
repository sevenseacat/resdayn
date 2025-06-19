defmodule Resdayn.Codex.World.Cell do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.World,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "cells"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]

    update :import_relationships do
      require_atomic? false
      accept [:source_file_ids]
      argument :new_references, {:array, :map}, allow_nil?: false
      argument :deleted_references, {:array, :map}, allow_nil?: false

      change manage_relationship(:deleted_references, :references, on_match: :destroy)

      change {Resdayn.Codex.Changes.OptimizedRelationshipImport,
              argument: :new_references,
              relationship: :references,
              related_resource: Resdayn.Codex.World.Cell.CellReference,
              parent_key: :cell_id,
              on_missing: :ignore}
    end
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false
    attribute :name, :string
    attribute :grid_position, {:array, :integer}, constraints: [min: 2, max: 2]
    attribute :water_height, :float
    attribute :light, __MODULE__.Light
    attribute :map_color, :color

    attribute :cell_flags, {:array, __MODULE__.Flag}, default: []

    # To handle:
    # * deleted references
    # * moved references
  end

  relationships do
    belongs_to :region, Resdayn.Codex.World.Region

    has_many :references, __MODULE__.CellReference
  end
end
