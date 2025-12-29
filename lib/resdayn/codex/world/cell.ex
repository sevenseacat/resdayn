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

    read :named_cells_in_region do
      argument :region_id, :string, allow_nil?: false

      filter expr(region_id == ^arg(:region_id) and not is_nil(name))

      prepare build(sort: [name: :asc])
    end
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false
    attribute :name, :string
    attribute :grid_position, {:array, :integer}, constraints: [min: 2, max: 2]
    attribute :water_height, :float
    attribute :light, __MODULE__.Light
    attribute :map_color, Resdayn.Codex.Types.Color

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
