defmodule Resdayn.Codex.Dialogue.JournalEntry do
  use Ash.Resource,
    domain: Resdayn.Codex.Dialogue,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "journal_entries"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read, :create, :update, :destroy]
    default_accept [:id, :index, :content, :finishes_quest, :restarts_quest, :quest_id]
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false
    attribute :index, :integer, allow_nil?: false, constraints: [min: 0]

    attribute :content, :string

    attribute :finishes_quest, :boolean, default: false
    attribute :restarts_quest, :boolean, default: false
  end

  relationships do
    belongs_to :quest, Resdayn.Codex.Dialogue.Quest, attribute_type: :string
  end
end
