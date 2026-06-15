defmodule Resdayn.Catalog.Assets.SoundGenerator do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.Assets,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable, Resdayn.Catalog.Referencable]

  postgres do
    table "sound_generators"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, Resdayn.Catalog.Types.RecordId, primary_key?: true, allow_nil?: false
    attribute :creature_key, :string
    attribute :sound_type, __MODULE__.SoundType, allow_nil?: false
  end

  relationships do
    belongs_to :sound, Resdayn.Catalog.Assets.Sound
  end
end
