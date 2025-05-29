defmodule Resdayn.Codex.Assets.SoundGenerator do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Assets,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable, Resdayn.Codex.Referencable]

  postgres do
    table "sound_generators"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false
    attribute :creature_key, :string
    attribute :sound_type, __MODULE__.SoundType, allow_nil?: false
  end

  relationships do
    belongs_to :sound, Resdayn.Codex.Assets.Sound, attribute_type: :string
  end
end
