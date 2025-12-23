defmodule Resdayn.Codex.Mechanics.Enchantment do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Mechanics,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "enchantments"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false
    attribute :type, __MODULE__.Type, allow_nil?: false
    attribute :cost, :integer, allow_nil?: false
    attribute :charge, :integer, allow_nil?: false
    attribute :autocalc, :boolean, allow_nil?: false

    attribute :effects, {:array, Resdayn.Codex.Mechanics.AppliedMagicEffect},
      allow_nil?: false,
      default: []
  end
end
