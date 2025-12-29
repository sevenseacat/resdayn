defmodule Resdayn.Codex.Search.SearchIndex do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Search,
    data_layer: AshPostgres.DataLayer

  require Ash.Query

  postgres do
    table "search_index"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]

    read :search do
      argument :query, :ci_string, allow_nil?: false

      filter expr(contains(name, ^arg(:query)))
      prepare build(sort: [:name], limit: 20)
    end
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false
    attribute :name, :string, allow_nil?: false
    attribute :type, :atom, allow_nil?: false
    attribute :icon_filename, :string
  end
end
