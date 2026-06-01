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

    has_many :actor_involvements, Resdayn.Codex.QuestAnalysis.ActorInvolvement
    has_many :item_involvements, Resdayn.Codex.QuestAnalysis.ItemInvolvement
  end

  calculations do
    calculate :related_npcs,
              :term,
              {__MODULE__.ActorsWithRoles, involvements: :npc_involvements, actor: :npc}

    calculate :related_creatures,
              :term,
              {__MODULE__.ActorsWithRoles, involvements: :creature_involvements, actor: :creature}

    calculate :related_items,
              :term,
              {__MODULE__.ItemsWithRoles, involvements: :item_involvements}

    calculate :actor_count, :integer, expr(npc_count + creature_count)
  end


  aggregates do
    count :npc_count, :npc_involvements, field: :npc_id, uniq?: true
    count :creature_count, :creature_involvements, field: :creature_id, uniq?: true
    count :item_count, :item_involvements, field: :object_id, uniq?: true

    list :related_dialogue_topics, [:actor_involvements, :dialogue_topic], :id do
      uniq? true
    end
  end
end
