defmodule Resdayn.Codex.Dialogue.Quest do
  use Ash.Resource,
    domain: Resdayn.Codex.Dialogue,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "quests"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]

    update :import_relationships do
      require_atomic? false
      accept [:name]

      argument :entries, {:array, :map}, allow_nil?: false, default: []

      change {Resdayn.Codex.Changes.OptimizedRelationshipImport,
              argument: :entries,
              relationship: :journal_entries,
              related_resource: Resdayn.Codex.Dialogue.JournalEntry,
              parent_key: :quest_id,
              id_field: :id,
              on_missing: :ignore}
    end
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false
    attribute :name, :string, allow_nil?: false
  end

  relationships do
    has_many :journal_entries, Resdayn.Codex.Dialogue.JournalEntry
  end
end
