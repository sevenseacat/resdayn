defmodule Resdayn.Codex.Mechanics.Spell do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Mechanics,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "spells"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false

    attribute :name, :string, allow_nil?: true
    attribute :type, __MODULE__.Type, allow_nil?: false
    attribute :cost, :integer, allow_nil?: false

    attribute :spell_flags, {:array, Resdayn.Codex.Mechanics.SpellFlag},
      allow_nil?: false,
      default: []

    attribute :effects, {:array, __MODULE__.Effect},
      allow_nil?: false,
      default: []
  end
end
