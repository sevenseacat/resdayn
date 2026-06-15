defmodule Resdayn.Catalog.Mechanics.Script do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.Mechanics,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable]

  postgres do
    table "scripts"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, Resdayn.Catalog.Types.RecordId, primary_key?: true, allow_nil?: false

    attribute :text, :string, allow_nil?: false
    attribute :local_variables, {:array, :string}, default: []
    attribute :start_script, :boolean, default: false
  end
end
