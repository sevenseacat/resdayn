defmodule Resdayn.Codex.World.Region do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.World,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "regions"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false
    attribute :name, :string, allow_nil?: true
    attribute :weather, __MODULE__.Weather, allow_nil?: false
    attribute :map_color, Resdayn.Codex.Types.Color, allow_nil?: true

    attribute :sounds, {:array, __MODULE__.RegionSound},
      allow_nil?: false,
      default: []
  end

  relationships do
    belongs_to :disturb_sleep_creature, Resdayn.Codex.World.CreatureLevelledList,
      attribute_type: :string,
      allow_nil?: true

    has_many :cells, Resdayn.Codex.World.Cell
  end

  aggregates do
    count :cell_count, :cells
  end
end
