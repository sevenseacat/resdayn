defmodule Resdayn.Codex.Assets.Light do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Assets,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable, Resdayn.Codex.Referencable]

  postgres do
    table "lights"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
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
    belongs_to :script, Resdayn.Codex.Mechanics.Script
    belongs_to :sound, Resdayn.Codex.Assets.Sound
  end
end
