defmodule Resdayn.Codex.Mechanics.AppliedMagicEffect do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Mechanics,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "applied_magic_effects"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :parent_type, __MODULE__.ParentType,
      primary_key?: true,
      allow_nil?: false

    attribute :parent_id, :string,
      primary_key?: true,
      allow_nil?: false

    attribute :index, :integer,
      primary_key?: true,
      allow_nil?: false

    attribute :duration, :integer, allow_nil?: false, public?: true

    attribute :magnitude, Resdayn.Codex.Types.Range,
      allow_nil?: false,
      public?: true,
      constraints: [validate?: false]

    attribute :range, Resdayn.Codex.MagicRange, allow_nil?: false, public?: true
    attribute :area, :integer, allow_nil?: false, public?: true
  end

  relationships do
    belongs_to :magic_effect, Resdayn.Codex.Mechanics.MagicEffect,
      allow_nil?: false,
      public?: true,
      attribute_type: :string
  end
end
