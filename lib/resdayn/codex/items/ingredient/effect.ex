defmodule Resdayn.Codex.Items.Ingredient.Effect do
  use Ash.Resource, otp_app: :resdayn, data_layer: :embedded

  changes do
    change Resdayn.Codex.Items.Changes.UnsetInvalidEffectValues
  end

  relationships do
    belongs_to :magic_effect, Resdayn.Codex.Mechanics.MagicEffect,
      allow_nil?: false,
      attribute_type: :integer,
      public?: true

    belongs_to :skill, Resdayn.Codex.Characters.Skill, attribute_type: :integer, public?: true

    belongs_to :attribute, Resdayn.Codex.Mechanics.Attribute,
      attribute_type: :integer,
      public?: true
  end
end
