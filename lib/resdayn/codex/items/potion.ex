defmodule Resdayn.Codex.Items.Potion do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Items,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable, Resdayn.Codex.Referencable]

  postgres do
    table "potions"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false
    attribute :name, :string, allow_nil?: false
    attribute :nif_model_filename, :string
    attribute :icon_filename, :string
    attribute :weight, :float
    attribute :value, :integer
    attribute :autocalc, :boolean, default: false
    attribute :effects, {:array, __MODULE__.Effect}, allow_nil?: false, default: []
  end

  relationships do
    belongs_to :script, Resdayn.Codex.Mechanics.Script
  end
end
