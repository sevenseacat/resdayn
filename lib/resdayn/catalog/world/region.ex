defmodule Resdayn.Catalog.World.Region do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.World,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable]

  postgres do
    table "regions"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, Resdayn.Catalog.Types.RecordId, primary_key?: true, allow_nil?: false
    attribute :name, :string, allow_nil?: true
    attribute :weather, __MODULE__.Weather, allow_nil?: false
    attribute :map_color, Resdayn.Catalog.Types.Color, allow_nil?: true

    attribute :sounds, {:array, __MODULE__.RegionSound},
      allow_nil?: false,
      default: []
  end

  relationships do
    belongs_to :disturb_sleep_creature, Resdayn.Catalog.World.CreatureLevelledList,
      allow_nil?: true

    has_many :cells, Resdayn.Catalog.World.Cell
  end

  aggregates do
    count :cell_count, :cells
  end
end
