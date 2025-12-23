defmodule Resdayn.Codex.Mechanics.MagicEffect do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Mechanics,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "magic_effects"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false
  end

  relationships do
    belongs_to :template, Resdayn.Codex.Mechanics.MagicEffectTemplate,
      allow_nil?: false,
      attribute_type: :integer

    belongs_to :skill, Resdayn.Codex.Characters.Skill, attribute_type: :integer

    belongs_to :attribute, Resdayn.Codex.Mechanics.Attribute, attribute_type: :integer

    has_many :ingredient_effects, Resdayn.Codex.Items.Ingredient.Effect
  end

  calculations do
    calculate :name, :string, Resdayn.Codex.Calculations.EffectName
    calculate :icon_filename, :string, Resdayn.Codex.Calculations.ConvertedIconFilename
  end
end
