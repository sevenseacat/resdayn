defmodule Resdayn.Codex.Items.Book do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Items,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "books"
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
    attribute :icon_filename, :string

    attribute :enchantment_points, :integer, allow_nil?: false, constraints: [min: 0]
    attribute :scroll, :boolean, default: false

    attribute :content, :string
  end

  relationships do
    belongs_to :script, Resdayn.Codex.Mechanics.Script, attribute_type: :string
    belongs_to :enchantment, Resdayn.Codex.Mechanics.Enchantment, attribute_type: :string
    belongs_to :skill, Resdayn.Codex.Characters.Skill, attribute_type: :integer
  end
end
