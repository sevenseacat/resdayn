defmodule Resdayn.Codex.Items.AlchemyApparatus do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Items,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "alchemy_apparatus"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  changes do
    change {Resdayn.Codex.Changes.CreateReferencableObject, object_type: :alchemy_apparatus},
      on: [:create]
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false
    attribute :name, :string, allow_nil?: false
    attribute :type, __MODULE__.Type, allow_nil?: false
    attribute :nif_model_filename, :string
    attribute :icon_filename, :string
    attribute :weight, :float
    attribute :value, :integer
    attribute :quality, :float
  end

  relationships do
    belongs_to :script, Resdayn.Codex.Mechanics.Script, attribute_type: :string

    belongs_to :referencable_object, Resdayn.Codex.World.ReferencableObject,
      source_attribute: :id,
      destination_attribute: :id,
      define_attribute?: false
  end
end
