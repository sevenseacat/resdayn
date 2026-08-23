defmodule Resdayn.Catalog.Items.Weapon do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.Items,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable, Resdayn.Catalog.Referencable]

  postgres do
    table "weapons"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, Resdayn.Catalog.Types.RecordId, primary_key?: true, allow_nil?: false

    attribute :name, :string
    attribute :type, __MODULE__.Type, allow_nil?: false
    attribute :value, :integer, allow_nil?: false, constraints: [min: 0]
    attribute :weight, :decimal, allow_nil?: false, constraints: [min: 0]
    attribute :nif_model_filename, :string, allow_nil?: false
    attribute :icon_filename, :string
    attribute :enchantment_points, :integer, allow_nil?: false, constraints: [min: 0, max: 65_535]

    attribute :health, :integer, allow_nil?: false, constraints: [min: 0, max: 65_535]
    attribute :speed, :float, allow_nil?: false, constraints: [min: 0]
    attribute :reach, :float, allow_nil?: false, constraints: [min: 0]

    attribute :chop_magnitude, Resdayn.Catalog.Types.Range, allow_nil?: false
    attribute :slash_magnitude, Resdayn.Catalog.Types.Range, allow_nil?: false
    attribute :thrust_magnitude, Resdayn.Catalog.Types.Range, allow_nil?: false

    attribute :weapon_flags, {:array, __MODULE__.Flag}, default: []
  end

  relationships do
    belongs_to :script, Resdayn.Catalog.Mechanics.Script
    belongs_to :enchantment, Resdayn.Catalog.Mechanics.Enchantment
  end
end
