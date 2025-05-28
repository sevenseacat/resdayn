defmodule Resdayn.Codex.Assets.Sound do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Assets,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable, Resdayn.Codex.Referencable]

  postgres do
    table "sounds"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false

    attribute :filename, :string, allow_nil?: true
    attribute :volume, :integer, allow_nil?: false, constraints: [min: 0, max: 255]
    attribute :range, :range, allow_nil?: false, constraints: [validate?: false]
  end
end
