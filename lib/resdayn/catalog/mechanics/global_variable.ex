defmodule Resdayn.Catalog.Mechanics.GlobalVariable do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.Mechanics,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable]

  postgres do
    table "global_variables"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, Resdayn.Catalog.Types.RecordId, primary_key?: true, allow_nil?: false
    attribute :value, Resdayn.Catalog.Types.Number, allow_nil?: false
  end
end
