defmodule Resdayn.Catalog.Items.MiscellaneousItem do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.Items,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable, Resdayn.Catalog.Referencable]

  postgres do
    table "miscellaneous_items"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, Resdayn.Catalog.Types.RecordId, primary_key?: true, allow_nil?: false

    attribute :name, :string, allow_nil?: false
    attribute :value, :integer, allow_nil?: false, constraints: [min: 0]
    attribute :weight, :decimal, allow_nil?: false, constraints: [min: 0]

    attribute :nif_model_filename, :string, allow_nil?: false
    attribute :icon_filename, :string, allow_nil?: false
  end

  relationships do
    belongs_to :script, Resdayn.Catalog.Mechanics.Script
  end
end
