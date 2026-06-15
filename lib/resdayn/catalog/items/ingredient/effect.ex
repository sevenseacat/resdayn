defmodule Resdayn.Catalog.Items.Ingredient.Effect do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.Items,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "ingredient_effects"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  relationships do
    belongs_to :ingredient, Resdayn.Catalog.Items.Ingredient,
      primary_key?: true,
      allow_nil?: false

    belongs_to :magic_effect, Resdayn.Catalog.Mechanics.MagicEffect,
      primary_key?: true,
      allow_nil?: false
  end
end
