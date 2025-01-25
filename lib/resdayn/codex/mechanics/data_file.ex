defmodule Resdayn.Codex.Mechanics.DataFile do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Mechanics,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "data_files"
    repo Resdayn.Repo
  end

  actions do
    create :import do
      accept [:*]
      upsert? true
      upsert_fields :replace_all
    end
  end

  attributes do
    attribute :filename, :string, primary_key?: true, allow_nil?: false, public?: true

    attribute :description, :string, public?: true
    attribute :version, :decimal, allow_nil?: false, public?: true
    attribute :master, :boolean, public?: true, default: false
    attribute :company, :string, public?: true
    attribute :dependencies, {:array, __MODULE__.Dependency}, default: [], public?: true

    attribute :flags, Resdayn.Codex.Flags, allow_nil?: false, public?: true
  end
end
