defmodule Resdayn.Codex.Items.Weapon do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Items,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable, Resdayn.Codex.Referencable]

  postgres do
    table "weapons"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read, :create, :update, :destroy]
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false, public?: true

    attribute :name, :string, public?: true
    attribute :type, __MODULE__.Type, allow_nil?: false, public?: true
    attribute :value, :integer, allow_nil?: false, constraints: [min: 0], public?: true
    attribute :weight, :decimal, allow_nil?: false, constraints: [min: 0], public?: true
    attribute :nif_model_filename, :string, allow_nil?: false
    attribute :icon_filename, :string
    attribute :enchantment_points, :integer, allow_nil?: false, constraints: [min: 0]

    attribute :health, :integer, allow_nil?: false, constraints: [min: 0]
    attribute :speed, :float, allow_nil?: false, constraints: [min: 0]
    attribute :reach, :float, allow_nil?: false, constraints: [min: 0]

    attribute :chop_magnitude, Resdayn.Codex.Types.Range,
      allow_nil?: false,
      public?: true

    attribute :slash_magnitude, Resdayn.Codex.Types.Range,
      allow_nil?: false,
      public?: true

    attribute :thrust_magnitude, Resdayn.Codex.Types.Range,
      allow_nil?: false,
      public?: true

    attribute :weapon_flags, {:array, __MODULE__.Flag}, default: []
  end

  relationships do
    belongs_to :script, Resdayn.Codex.Mechanics.Script
    belongs_to :enchantment, Resdayn.Codex.Mechanics.Enchantment
  end
end
