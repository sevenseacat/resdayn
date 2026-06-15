defmodule Resdayn.Catalog.World.Door do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.World,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable, Resdayn.Catalog.Referencable]

  postgres do
    table "doors"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, Resdayn.Catalog.Types.RecordId, primary_key?: true, allow_nil?: false
    attribute :name, :string
    attribute :nif_model_filename, :string, allow_nil?: false
  end

  relationships do
    belongs_to :script, Resdayn.Catalog.Mechanics.Script
    belongs_to :open_sound, Resdayn.Catalog.Assets.Sound
    belongs_to :close_sound, Resdayn.Catalog.Assets.Sound
  end
end
