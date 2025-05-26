defmodule Resdayn.Codex.Characters.Birthsign do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Characters,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "birthsigns"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false
    attribute :name, :string, allow_nil?: false
    attribute :description, :string
    attribute :artwork_filename, :string

    attribute :spells, {:array, Resdayn.Codex.Characters.SpellLink},
      allow_nil?: false,
      default: []
  end

  relationships do
  end
end
