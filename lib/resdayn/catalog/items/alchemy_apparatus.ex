defmodule Resdayn.Catalog.Items.AlchemyApparatus do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.Items,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable, Resdayn.Catalog.Referencable]

  postgres do
    table "alchemy_apparatus"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, Resdayn.Catalog.Types.RecordId, primary_key?: true, allow_nil?: false
    attribute :name, :string, allow_nil?: false
    attribute :type, __MODULE__.Type, allow_nil?: false
    attribute :nif_model_filename, :string, allow_nil?: false
    attribute :icon_filename, :string, allow_nil?: false
    attribute :weight, :float, allow_nil?: false, constraints: [min: 0]
    attribute :value, :integer, allow_nil?: false, constraints: [min: 0]
    attribute :quality, :float, allow_nil?: false, constraints: [min: 0]
  end

  relationships do
    belongs_to :script, Resdayn.Catalog.Mechanics.Script
  end
end
