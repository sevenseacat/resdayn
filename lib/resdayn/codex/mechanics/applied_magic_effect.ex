defmodule Resdayn.Codex.Mechanics.AppliedMagicEffect do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Mechanics,
    data_layer: :embedded

  attributes do
    integer_primary_key :id

    attribute :duration, :integer, allow_nil?: false, public?: true

    attribute :magnitude, Resdayn.Codex.Types.Range,
      allow_nil?: false,
      public?: true,
      constraints: [validate?: false]

    attribute :range, Resdayn.Codex.MagicRange, allow_nil?: false, public?: true
    attribute :area, :integer, allow_nil?: false, public?: true
  end

  relationships do
    belongs_to :magic_effect, Resdayn.Codex.Mechanics.MagicEffect,
      allow_nil?: false,
      public?: true,
      attribute_writable?: true
  end
end
