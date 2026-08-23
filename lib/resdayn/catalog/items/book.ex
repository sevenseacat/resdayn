defmodule Resdayn.Catalog.Items.Book do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.Items,
    data_layer: AshPostgres.DataLayer,
    extensions: [
      Resdayn.Catalog.Importable,
      Resdayn.Catalog.Referencable,
      Resdayn.Catalog.Exportable
    ]

  postgres do
    table "books"
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
    attribute :icon_filename, :string

    attribute :enchantment_points, :integer, allow_nil?: false, constraints: [min: 0]
    attribute :scroll, :boolean, default: false

    attribute :text, :string
  end

  relationships do
    belongs_to :script, Resdayn.Catalog.Mechanics.Script
    belongs_to :enchantment, Resdayn.Catalog.Mechanics.Enchantment
    belongs_to :skill, Resdayn.Catalog.Characters.Skill, attribute_type: :integer
  end
end
