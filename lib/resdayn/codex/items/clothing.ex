defmodule Resdayn.Codex.Items.Clothing do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Items,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable, Resdayn.Codex.Referencable]

  postgres do
    table "clothing"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false

    attribute :name, :string
    attribute :type, __MODULE__.Type, allow_nil?: false
    attribute :value, :integer, allow_nil?: false, constraints: [min: 0]
    attribute :weight, :decimal, allow_nil?: false, constraints: [min: 0]
    attribute :nif_model_filename, :string, allow_nil?: false
    attribute :icon_filename, :string
    attribute :enchantment_points, :integer, allow_nil?: false, constraints: [min: 0]

    attribute :body_part_coverings, {:array, Resdayn.Codex.Characters.BodyPart.Coverable},
      default: []
  end

  relationships do
    belongs_to :script, Resdayn.Codex.Mechanics.Script
    belongs_to :enchantment, Resdayn.Codex.Mechanics.Enchantment
  end
end
