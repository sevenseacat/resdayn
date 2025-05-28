defmodule Resdayn.Codex.Items.MiscellaneousItem do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Items,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "miscellaneous_items"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  changes do
    change {Resdayn.Codex.Changes.CreateReferencableObject, object_type: :miscellaneous_item},
      on: [:create]
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false

    attribute :name, :string, allow_nil?: false
    attribute :value, :integer, allow_nil?: false, constraints: [min: 0]
    attribute :weight, :decimal, allow_nil?: false, constraints: [min: 0]

    attribute :nif_model_filename, :string, allow_nil?: false
    attribute :icon_filename, :string, allow_nil?: false
  end

  relationships do
    belongs_to :script, Resdayn.Codex.Mechanics.Script, attribute_type: :string

    belongs_to :referencable_object, Resdayn.Codex.World.ReferencableObject,
      source_attribute: :id,
      destination_attribute: :id,
      define_attribute?: false
  end
end
