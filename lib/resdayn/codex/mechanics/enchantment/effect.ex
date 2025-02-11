defmodule Resdayn.Codex.Mechanics.Enchantment.Effect do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Mechanics,
    data_layer: :embedded

  attributes do
    attribute :duration, :integer, allow_nil?: false, public?: true

    attribute :magnitude, :range,
      allow_nil?: false,
      public?: true,
      constraints: [validate?: false]

    attribute :range, Resdayn.Codex.Mechanics.Enchantment.Range, allow_nil?: false, public?: true
    attribute :area, :integer, allow_nil?: false, public?: true
  end

  relationships do
    belongs_to :skill, Resdayn.Codex.Characters.Skill, attribute_type: :integer, public?: true

    belongs_to :attribute, Resdayn.Codex.Mechanics.Attribute,
      attribute_type: :integer,
      public?: true

    belongs_to :magic_effect, Resdayn.Codex.Mechanics.MagicEffect,
      attribute_type: :integer,
      allow_nil?: false,
      public?: true
  end
end
