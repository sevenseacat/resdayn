defmodule Resdayn.Catalog.Items.Clothing do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.Items,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable, Resdayn.Catalog.Referencable]

  postgres do
    table "clothing"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, Resdayn.Catalog.Types.RecordId, primary_key?: true, allow_nil?: false

    attribute :name, :string
    attribute :type, __MODULE__.Type, allow_nil?: false
    attribute :value, :integer, allow_nil?: false, constraints: [min: 0, max: 65_535]
    attribute :weight, :decimal, allow_nil?: false, constraints: [min: 0]
    attribute :nif_model_filename, :string, allow_nil?: false
    attribute :icon_filename, :string
    attribute :enchantment_points, :integer, allow_nil?: false, constraints: [min: 0, max: 65_535]

    attribute :body_part_coverings, {:array, Resdayn.Catalog.Characters.BodyPart.Coverable},
      default: []
  end

  relationships do
    belongs_to :script, Resdayn.Catalog.Mechanics.Script
    belongs_to :enchantment, Resdayn.Catalog.Mechanics.Enchantment
  end
end
