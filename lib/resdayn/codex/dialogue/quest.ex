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
  end

  attributes do
    attribute :id, :ci_string, primary_key?: true, allow_nil?: false
    attribute :name, :string, allow_nil?: false
  end

  relationships do
    belongs_to :faction, Resdayn.Codex.Characters.Faction
    has_many :quest_versions, Resdayn.Codex.Dialogue.QuestVersion
  end
end
