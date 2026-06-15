defmodule Resdayn.Catalog.Dialogue.JournalEntry do
  use Ash.Resource,
    domain: Resdayn.Catalog.Dialogue,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable]

  postgres do
    table "journal_entries"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read, :create, :update, :destroy]
    default_accept [:id, :index, :content, :finishes_quest, :restarts_quest, :quest_version_id]
  end

  attributes do
    attribute :id, :ci_string, primary_key?: true, allow_nil?: false
    attribute :index, :integer, allow_nil?: false, constraints: [min: 0]

    attribute :content, :string

    attribute :finishes_quest, :boolean, default: false
    attribute :restarts_quest, :boolean, default: false
  end

  relationships do
    belongs_to :quest_version, Resdayn.Catalog.Dialogue.QuestVersion
  end
end
