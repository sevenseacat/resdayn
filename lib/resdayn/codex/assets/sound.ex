defmodule Resdayn.Codex.Assets.Sound do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Assets,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "sounds"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  changes do
    change {Resdayn.Codex.Changes.CreateReferencableObject, object_type: :sound}, on: [:create]
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false

    attribute :filename, :string, allow_nil?: true
    attribute :volume, :integer, allow_nil?: false, constraints: [min: 0, max: 255]
    attribute :range, :range, allow_nil?: false, constraints: [validate?: false]
  end

  relationships do
    belongs_to :referencable_object, Resdayn.Codex.World.ReferencableObject,
      source_attribute: :id,
      destination_attribute: :id,
      define_attribute?: false
  end
end
