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

    has_many :npc_involvements, Resdayn.Codex.QuestAnalysis.ActorInvolvement do
      filter expr(not is_nil(npc_id))
    end

    has_many :creature_involvements, Resdayn.Codex.QuestAnalysis.ActorInvolvement do
      filter expr(not is_nil(creature_id))
    end
  end

  calculations do
    calculate :related_npcs,
              :term,
              {__MODULE__.ActorsWithRoles, involvements: :npc_involvements, actor: :npc}

    calculate :related_creatures,
              :term,
              {__MODULE__.ActorsWithRoles, involvements: :creature_involvements, actor: :creature}
  end
end
