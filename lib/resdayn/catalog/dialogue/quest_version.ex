defmodule Resdayn.Catalog.Dialogue.QuestVersion do
  use Ash.Resource,
    domain: Resdayn.Catalog.Dialogue,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable]

  postgres do
    table "quest_versions"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, :ci_string, primary_key?: true, allow_nil?: false
    attribute :name, :string
  end

  relationships do
    belongs_to :quest, Resdayn.Catalog.Dialogue.Quest

    has_many :journal_entries, Resdayn.Catalog.Dialogue.JournalEntry do
      sort index: :asc
    end
  end

  aggregates do
    count :journal_count, :journal_entries
  end
end
