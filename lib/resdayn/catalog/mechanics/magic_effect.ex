defmodule Resdayn.Catalog.Mechanics.MagicEffect do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.Mechanics,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "magic_effects"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, :ci_string, primary_key?: true, allow_nil?: false
  end

  relationships do
    belongs_to :template, Resdayn.Catalog.Mechanics.MagicEffectTemplate,
      allow_nil?: false,
      attribute_type: :integer

    belongs_to :skill, Resdayn.Catalog.Characters.Skill, attribute_type: :integer

    belongs_to :attribute, Resdayn.Catalog.Mechanics.Attribute, attribute_type: :integer

    has_many :ingredient_effects, Resdayn.Catalog.Items.Ingredient.Effect

    many_to_many :ingredients, Resdayn.Catalog.Items.Ingredient,
      join_relationship: :ingredient_effects
  end

  calculations do
    calculate :name, :string, Resdayn.Catalog.Calculations.EffectName
  end

  aggregates do
    first :icon_filename, :template, :icon_filename
  end
end
