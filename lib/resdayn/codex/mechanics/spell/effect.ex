defmodule Resdayn.Codex.Mechanics.Spell.Effect do
  use Ash.Resource,
    otp_app: :resdayn,
    data_layer: :embedded

  attributes do
    attribute :duration, :integer, allow_nil?: false, public?: true
    attribute :magnitude, :map, allow_nil?: false, public?: true
    attribute :range, Resdayn.Codex.Mechanics.Spell.Range, allow_nil?: false, public?: true
    attribute :area, :integer, allow_nil?: false, public?: true
  end

  relationships do
    belongs_to :magic_effect, Resdayn.Codex.Mechanics.MagicEffect,
      attribute_type: :integer,
      allow_nil?: false,
      public?: true

    belongs_to :skill, Resdayn.Codex.Characters.Skill,
      attribute_type: :integer,
      public?: true

    belongs_to :attribute, Resdayn.Codex.Mechanics.Attribute,
      attribute_type: :integer,
      public?: true
  end
end