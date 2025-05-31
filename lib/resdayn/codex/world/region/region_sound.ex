defmodule Resdayn.Codex.World.Region.RegionSound do
  use Ash.Resource,
    otp_app: :resdayn,
    data_layer: :embedded

  actions do
    defaults [:read, :create, :update, :destroy]
    default_accept [:chance, :sound_id]
  end

  attributes do
    attribute :chance, :integer, allow_nil?: false, constraints: [min: 0, max: 255], public?: true
  end

  relationships do
    belongs_to :sound, Resdayn.Codex.Assets.Sound
  end
end
