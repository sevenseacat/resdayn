defmodule Resdayn.Catalog.Mechanics.DataFile do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.Mechanics,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable]

  postgres do
    table "data_files"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, Resdayn.Catalog.Types.RecordId, primary_key?: true, allow_nil?: false
    attribute :filename, :string, allow_nil?: false

    attribute :description, :string
    attribute :version, :decimal, allow_nil?: false
    attribute :master, :boolean, default: false
    attribute :company, :string
    attribute :dependencies, {:array, __MODULE__.Dependency}, default: []
  end
end
