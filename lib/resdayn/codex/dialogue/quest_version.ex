defmodule Resdayn.Codex.Dialogue.QuestVersion do
  use Ash.Resource,
    domain: Resdayn.Codex.Dialogue,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

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
    belongs_to :quest, Resdayn.Codex.Dialogue.Quest

    has_many :journal_entries, Resdayn.Codex.Dialogue.JournalEntry do
      sort index: :asc
    end
  end
end
