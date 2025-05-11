defmodule Resdayn.Codex.Items.Ingredient do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Items,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

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

    attribute :effects, {:array, __MODULE__.Effect}, allow_nil?: false, default: []
  end

  relationships do
    belongs_to :script, Resdayn.Codex.Mechanics.Script, attribute_type: :string
  end
end
