defmodule Resdayn.Catalog.Characters.Birthsign do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.Characters,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable]

  postgres do
    table "birthsigns"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, Resdayn.Catalog.Types.RecordId, primary_key?: true, allow_nil?: false
    attribute :name, :string, allow_nil?: false
    attribute :description, :string
    attribute :artwork_filename, :string

    attribute :spells, {:array, Resdayn.Catalog.Characters.SpellLink},
      allow_nil?: false,
      default: []
  end
end
