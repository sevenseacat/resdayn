defmodule Resdayn.Codex.World.TransportDestination do
  use Ash.Resource,
    otp_app: :resdayn,
    data_layer: :embedded

  attributes do
    attribute :coordinates, Resdayn.Codex.Types.Coordinates, allow_nil?: false, public?: true
  end

  relationships do
    belongs_to :cell, Resdayn.Codex.World.Cell,
      attribute_type: :string,
      allow_nil?: false,
      public?: true
  end
end
