defmodule Resdayn.Codex.Assets.StaticObject do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Assets,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "static_objects"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false
    attribute :nif_model_filename, :string
  end
end