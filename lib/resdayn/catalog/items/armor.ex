defmodule Resdayn.Catalog.Items.Armor do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.Items,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable, Resdayn.Catalog.Referencable]

  postgres do
    table "armor"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, Resdayn.Catalog.Types.RecordId, primary_key?: true, allow_nil?: false

    attribute :name, :string, allow_nil?: false
    attribute :type, __MODULE__.Type, allow_nil?: false
    attribute :value, :integer, allow_nil?: false, constraints: [min: 0]
    attribute :weight, :decimal, allow_nil?: false, constraints: [min: 0]
    attribute :class, __MODULE__.Class, allow_nil?: false
    attribute :nif_model_filename, :string, allow_nil?: false
    attribute :icon_filename, :string, allow_nil?: false
    attribute :enchantment_points, :integer, allow_nil?: false, constraints: [min: 0]

    attribute :body_part_coverings, {:array, Resdayn.Catalog.Characters.BodyPart.Coverable},
      default: []

    attribute :health, :integer, allow_nil?: false, constraints: [min: 0]
    attribute :armor_rating, :integer, allow_nil?: false, constraints: [min: 0]
  end

  relationships do
    belongs_to :script, Resdayn.Catalog.Mechanics.Script
    belongs_to :enchantment, Resdayn.Catalog.Mechanics.Enchantment
  end
end
