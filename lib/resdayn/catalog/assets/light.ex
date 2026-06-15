defmodule Resdayn.Catalog.Assets.Light do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.Assets,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable, Resdayn.Catalog.Referencable]

  postgres do
    table "lights"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, Resdayn.Catalog.Types.RecordId, primary_key?: true, allow_nil?: false
    attribute :name, :string
    attribute :nif_model_filename, :string
    attribute :icon_filename, :string
    attribute :weight, :float, constraints: [min: 0]
    attribute :value, :integer, constraints: [min: 0]
    attribute :time, :integer
    attribute :radius, :integer, constraints: [min: 0]
    attribute :color, Resdayn.Catalog.Types.Color

    attribute :light_flags, {:array, Resdayn.Catalog.Assets.LightFlag},
      allow_nil?: false,
      default: []
  end

  relationships do
    belongs_to :script, Resdayn.Catalog.Mechanics.Script
    belongs_to :sound, Resdayn.Catalog.Assets.Sound
  end
end
