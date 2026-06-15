defmodule Resdayn.Catalog.Items.Potion do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.Items,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable, Resdayn.Catalog.Referencable]

  postgres do
    table "potions"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, Resdayn.Catalog.Types.RecordId, primary_key?: true, allow_nil?: false
    attribute :name, :string, allow_nil?: false
    attribute :nif_model_filename, :string
    attribute :icon_filename, :string
    attribute :weight, :float, constraints: [min: 0]
    attribute :value, :integer, constraints: [min: 0]
    attribute :autocalc, :boolean, default: false
  end

  relationships do
    belongs_to :script, Resdayn.Catalog.Mechanics.Script

    has_many :effects, Resdayn.Catalog.Mechanics.AppliedMagicEffect do
      destination_attribute :parent_id
      filter expr(parent_type == :potion)
      sort index: :asc
    end
  end
end
