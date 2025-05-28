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
    attribute :id, :string, primary_key?: true, allow_nil?: false

    attribute :name, :string
    attribute :type, __MODULE__.Type, allow_nil?: false
    attribute :value, :integer, allow_nil?: false, constraints: [min: 0]
    attribute :weight, :decimal, allow_nil?: false, constraints: [min: 0]
    attribute :nif_model_filename, :string, allow_nil?: false
    attribute :icon_filename, :string
    attribute :enchantment_points, :integer, allow_nil?: false, constraints: [min: 0]

    attribute :health, :integer, allow_nil?: false, constraints: [min: 0]
    attribute :speed, :float, allow_nil?: false, constraints: [min: 0]
    attribute :reach, :float, allow_nil?: false, constraints: [min: 0]

    attribute :chop_magnitude, :range,
      allow_nil?: false,
      public?: true

    attribute :slash_magnitude, :range,
      allow_nil?: false,
      public?: true

    attribute :thrust_magnitude, :range,
      allow_nil?: false,
      public?: true

    attribute :weapon_flags, {:array, __MODULE__.Flag}, default: []
  end

  relationships do
    belongs_to :script, Resdayn.Codex.Mechanics.Script, attribute_type: :string
    belongs_to :enchantment, Resdayn.Codex.Mechanics.Enchantment, attribute_type: :string
  end
end
