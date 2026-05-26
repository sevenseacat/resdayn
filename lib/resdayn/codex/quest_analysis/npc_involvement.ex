defmodule Resdayn.Codex.QuestAnalysis.NPCInvolvement do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.QuestAnalysis,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "npc_involvements"
    repo Resdayn.Repo

    references do
      reference :quest, on_delete: :delete
      reference :quest_version, on_delete: :delete
      reference :npc, on_delete: :delete
      reference :script, on_delete: :delete

      # Response has a composite PK (topic_id + id); match_with adds the
      # second column so the FK references both halves.
      reference :dialogue_response,
        on_delete: :delete,
        match_with: [dialogue_response_topic_id: :topic_id]
    end

    # Source is either a dialogue response (both id columns set) or a
    # standalone script. Exactly one source-kind per row.
    check_constraints do
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

    # Second half of the composite FK to Response — paired with the
    # `dialogue_response_id` that belongs_to :dialogue_response generates.
    attribute :dialogue_response_topic_id, :ci_string
  end

  relationships do
    belongs_to :quest, Resdayn.Codex.Dialogue.Quest do
      allow_nil? false
    end

    belongs_to :quest_version, Resdayn.Codex.Dialogue.QuestVersion do
      allow_nil? false
    end

    belongs_to :npc, Resdayn.Codex.World.NPC do
      allow_nil? false
    end

    belongs_to :dialogue_response, Resdayn.Codex.Dialogue.Response
    belongs_to :script, Resdayn.Codex.Mechanics.Script
  end

  identities do
    identity :unique_involvement,
             [
               :quest_id,
               :quest_version_id,
               :npc_id,
               :reason,
               :dialogue_response_id,
               :dialogue_response_topic_id,
               :script_id
             ],
             nils_distinct?: false
  end
end
