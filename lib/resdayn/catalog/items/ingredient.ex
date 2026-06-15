defmodule Resdayn.Catalog.Items.Ingredient do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.Items,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable, Resdayn.Catalog.Referencable]

  postgres do
    table "ingredients"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, Resdayn.Catalog.Types.RecordId, primary_key?: true, allow_nil?: false

    attribute :name, :string, allow_nil?: false
    attribute :value, :integer, allow_nil?: false, constraints: [min: 0]
    attribute :weight, :decimal, allow_nil?: false, constraints: [min: 0]

    attribute :nif_model_filename, :string, allow_nil?: false
    attribute :icon_filename, :string, allow_nil?: false
  end

  relationships do
    belongs_to :script, Resdayn.Catalog.Mechanics.Script

    many_to_many :magic_effects, Resdayn.Catalog.Mechanics.MagicEffect,
      join_relationship: :ingredient_effects

    has_many :ingredient_effects, Resdayn.Catalog.Items.Ingredient.Effect
  end
end
