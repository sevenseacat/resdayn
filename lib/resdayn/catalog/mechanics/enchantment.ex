defmodule Resdayn.Catalog.Mechanics.Enchantment do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.Mechanics,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable]

  postgres do
    table "enchantments"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, Resdayn.Catalog.Types.RecordId, primary_key?: true, allow_nil?: false
    attribute :type, __MODULE__.Type, allow_nil?: false
    attribute :cost, :integer, allow_nil?: false, constraints: [min: 0]
    attribute :charge, :integer, allow_nil?: false, constraints: [min: 0]
    attribute :autocalc, :boolean, allow_nil?: false
  end

  relationships do
    has_many :effects, Resdayn.Catalog.Mechanics.AppliedMagicEffect do
      destination_attribute :parent_id
      filter expr(parent_type == :enchantment)
      sort index: :asc
    end
  end
end
