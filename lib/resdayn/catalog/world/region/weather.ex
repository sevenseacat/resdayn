defmodule Resdayn.Catalog.World.Region.Weather do
  use Ash.Resource,
    otp_app: :resdayn,
    data_layer: :embedded

  attributes do
    attribute :clear, :integer, allow_nil?: false, default: 0, public?: true
    attribute :cloudy, :integer, allow_nil?: false, default: 0, public?: true
    attribute :foggy, :integer, allow_nil?: false, default: 0, public?: true
    attribute :overcast, :integer, allow_nil?: false, default: 0, public?: true
    attribute :rain, :integer, allow_nil?: false, default: 0, public?: true
    attribute :thunder, :integer, allow_nil?: false, default: 0, public?: true
    attribute :ash, :integer, allow_nil?: false, default: 0, public?: true
    attribute :blight, :integer, allow_nil?: false, default: 0, public?: true
    attribute :snow, :integer, allow_nil?: false, default: 0, public?: true
    attribute :blizzard, :integer, allow_nil?: false, default: 0, public?: true
  end
end
