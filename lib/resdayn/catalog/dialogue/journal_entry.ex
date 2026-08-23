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
    defaults [:read]
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

    # Every transition in this entry's quest version. Reachability narrows these
    # to the ones advancing to *this* entry's index via the aggregate below.
    has_many :quest_version_transitions, Resdayn.Catalog.QuestAnalysis.Transition do
      source_attribute :quest_version_id
      destination_attribute :quest_version_id
    end
  end

  aggregates do
    # An entry is reachable when some transition in its quest version advances
    # to its index. Entries with no such transition are dead journal text the
    # player can never see.
    exists :reachable, :quest_version_transitions do
      filter expr(target_index == parent(index))
    end
  end
end
