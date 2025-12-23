defmodule Resdayn.Codex.Items.Ingredient.Effect do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Items,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "ingredient_effects"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  relationships do
    belongs_to :ingredient, Resdayn.Codex.Items.Ingredient,
      primary_key?: true,
      allow_nil?: false,
      attribute_type: :string

    belongs_to :magic_effect, Resdayn.Codex.Mechanics.MagicEffect,
      primary_key?: true,
      allow_nil?: false,
      attribute_type: :string
  end
end
