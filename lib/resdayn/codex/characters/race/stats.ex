defmodule Resdayn.Codex.Characters.Race.Stats do
  use Ash.Resource,
    otp_app: :resdayn,
    data_layer: :embedded

  attributes do
    attribute :height, :float, allow_nil?: false, public?: true
    attribute :weight, :float, allow_nil?: false, public?: true

    attribute :starting_attributes, {:array, Resdayn.Codex.Characters.AttributeValue},
      allow_nil?: false,
      default: [],
      public?: true
  end
end
