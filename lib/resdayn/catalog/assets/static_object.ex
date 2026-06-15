defmodule Resdayn.Catalog.Assets.StaticObject do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.Assets,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable, Resdayn.Catalog.Referencable]

  postgres do
    table "static_objects"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, Resdayn.Catalog.Types.RecordId, primary_key?: true, allow_nil?: false
    attribute :nif_model_filename, :string, allow_nil?: false
  end
end
