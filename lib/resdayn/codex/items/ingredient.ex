defmodule Resdayn.Codex.Items.Ingredient do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Items,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable, Resdayn.Codex.Referencable]

  postgres do
    table "ingredients"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false

    attribute :name, :string, allow_nil?: false
    attribute :value, :integer, allow_nil?: false, constraints: [min: 0]
    attribute :weight, :decimal, allow_nil?: false, constraints: [min: 0]

    attribute :nif_model_filename, :string, allow_nil?: false
    attribute :icon_filename, :string, allow_nil?: false
  end

  relationships do
    belongs_to :script, Resdayn.Codex.Mechanics.Script

    many_to_many :magic_effects, Resdayn.Codex.Mechanics.MagicEffect,
      join_relationship: :ingredient_effects

    has_many :ingredient_effects, Resdayn.Codex.Items.Ingredient.Effect
  end
end
