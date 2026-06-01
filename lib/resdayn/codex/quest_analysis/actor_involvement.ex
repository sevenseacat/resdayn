defmodule Resdayn.Codex.QuestAnalysis.ActorInvolvement do
  @moduledoc """
  An involvement row linking an actor (an NPC or a creature) to a quest,
  with a reason explaining why the actor is involved and a reference to the
  source record that caused the inclusion.

  Two independent XOR invariants per row:

  - **Subject**: exactly one of `npc_id` / `creature_id` is set — who is involved.
  - **Source**: exactly one of `(dialogue_response_id + dialogue_response_topic_id)`
    / `script_id` is set — how the involvement was found.

  The composite uniqueness invariant (with `NULLS NOT DISTINCT`) prevents
  duplicate rows for the same (quest, actor, reason, source) tuple.
  """

  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.QuestAnalysis,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "actor_involvements"
    repo Resdayn.Repo

    # The unique-involvement index leads with `quest_id`, so it can't serve the
    # per-actor lookups behind the `related_quest_count` aggregate.
    # These actor-leading partial indexes make those an index-only scan (partial
    # because each row sets exactly one of npc_id/creature_id — see the
    # `exactly_one_subject` check constraint).
    custom_indexes do
      index [:npc_id, :quest_id], where: "npc_id IS NOT NULL"
      index [:creature_id, :quest_id], where: "creature_id IS NOT NULL"
    end

    references do
      reference :quest, on_delete: :delete
      reference :quest_version, on_delete: :delete
      reference :npc, on_delete: :delete
      reference :creature, on_delete: :delete
      reference :script, on_delete: :delete

      # Response has a composite PK (topic_id + id); match_with adds the
      # second column so the FK references both halves.
      reference :dialogue_response,
        on_delete: :delete,
        match_with: [dialogue_response_topic_id: :topic_id]
    end

    check_constraints do
      # Subject is exactly one of an NPC or a creature.
      check_constraint :npc_id,
        name: "exactly_one_subject",
        check: "(npc_id IS NOT NULL) <> (creature_id IS NOT NULL)",
        message: "exactly one of npc_id or creature_id must be set"

      # Source is exactly one of a dialogue response (both id columns set) or
      # a standalone script.
      check_constraint :dialogue_response_id,
        name: "exactly_one_source",
        check: """
        (
          (dialogue_response_id IS NOT NULL AND dialogue_response_topic_id IS NOT NULL AND script_id IS NULL)
          OR
          (dialogue_response_id IS NULL AND dialogue_response_topic_id IS NULL AND script_id IS NOT NULL)
        )
        """,
        message:
          "exactly one of (dialogue_response_id+dialogue_response_topic_id) or script_id must be set"
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [
        :reason,
        :quest_id,
        :quest_version_id,
        :npc_id,
        :creature_id,
        :dialogue_response_id,
        :dialogue_response_topic_id,
        :script_id
      ]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :reason, __MODULE__.Reason do
      allow_nil? false
    end
  end

  relationships do
    belongs_to :quest, Resdayn.Codex.Dialogue.Quest do
      allow_nil? false
    end

    belongs_to :quest_version, Resdayn.Codex.Dialogue.QuestVersion do
      allow_nil? false
    end

    belongs_to :npc, Resdayn.Codex.World.NPC
    belongs_to :creature, Resdayn.Codex.World.Creature
    belongs_to :dialogue_response, Resdayn.Codex.Dialogue.Response

    belongs_to :dialogue_topic, Resdayn.Codex.Dialogue.Topic,
      source_attribute: :dialogue_response_topic_id

    belongs_to :script, Resdayn.Codex.Mechanics.Script
  end

  identities do
    identity :unique_involvement,
             [
               :quest_id,
               :quest_version_id,
               :npc_id,
               :creature_id,
               :reason,
               :dialogue_response_id,
               :dialogue_response_topic_id,
               :script_id
             ],
             nils_distinct?: false
  end
end
