defmodule Resdayn.Codex.Mechanics.DataFile do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Mechanics,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "data_files"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :filename, :string, primary_key?: true, allow_nil?: false

    attribute :description, :string
    attribute :version, :decimal, allow_nil?: false
    attribute :master, :boolean, default: false
    attribute :company, :string
    attribute :dependencies, {:array, __MODULE__.Dependency}, default: []
  end
end
