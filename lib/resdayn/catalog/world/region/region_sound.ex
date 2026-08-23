defmodule Resdayn.Catalog.World.Region.RegionSound do
  use Ash.Resource,
    otp_app: :resdayn,
    data_layer: :embedded

  attributes do
    attribute :chance, :integer, allow_nil?: false, constraints: [min: 0, max: 255], public?: true
  end

  relationships do
    belongs_to :sound, Resdayn.Catalog.Assets.Sound, public?: true
  end
end
