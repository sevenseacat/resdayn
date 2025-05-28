defmodule Resdayn.Codex.Assets.Light do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Assets,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "lights"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  changes do
    change {Resdayn.Codex.Changes.CreateReferencableObject, object_type: :light}, on: [:create]
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false
    attribute :name, :string
    attribute :nif_model_filename, :string
    attribute :icon_filename, :string
    attribute :weight, :float
    attribute :value, :integer
    attribute :time, :integer
    attribute :radius, :integer
    attribute :color, :color

    attribute :light_flags, {:array, Resdayn.Codex.Assets.LightFlag},
      allow_nil?: false,
      default: []
  end

  relationships do
    belongs_to :script, Resdayn.Codex.Mechanics.Script, attribute_type: :string
    belongs_to :sound, Resdayn.Codex.Assets.Sound, attribute_type: :string

    belongs_to :referencable_object, Resdayn.Codex.World.ReferencableObject,
      source_attribute: :id,
      destination_attribute: :id,
      define_attribute?: false
  end
end
