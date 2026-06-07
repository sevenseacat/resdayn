defmodule Resdayn.Codex.QuestAnalysis.Transition do
  @moduledoc """
  A `Journal "QuestID" N` call site — the atom of quest state changes.

  Each row records the source (a dialogue response or a standalone script)
  that contains the call and the `target_index` the call advances the quest
  to. Transitions are the foundation of Phase C's state machine — see
  `docs/quest-analyzer-v4.md` §4.4.

  The C1 pass populates the bare fields (source + `target_index`). Later
  passes fill in:

  - `from_min` / `from_max` — derived from `:journal` conditions on the
    source (C2), then narrowed by known indices (C3), choice-chain
    fallback (C4), topic-availability fallback (C5).
  - `is_quest_start` / `is_quest_finish` — derived after the precondition
    chain is complete (C6).

  Source XOR mirrors `ActorInvolvement` / `ItemInvolvement`: exactly one
  of `(dialogue_response_id + dialogue_response_topic_id)` / `script_id`
  is set.
  """

  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.QuestAnalysis,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "transitions"
    repo Resdayn.Repo

    references do
      reference :quest, on_delete: :delete
      reference :quest_version, on_delete: :delete
      reference :script, on_delete: :delete

      reference :dialogue_response,
        on_delete: :delete,
        match_with: [dialogue_response_topic_id: :topic_id]
    end

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
        :target_index,
        :quest_id,
        :quest_version_id,
        :dialogue_response_id,
        :dialogue_response_topic_id,
        :script_id
      ]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :target_index, :integer do
      allow_nil? false
      constraints min: 0
    end

    attribute :dialogue_response_topic_id, :ci_string

    # Filled by later phases — nullable for now.
    attribute :from_min, :integer
    attribute :from_max, :integer
    attribute :is_quest_start, :boolean
    attribute :is_quest_finish, :boolean
  end

  relationships do
    belongs_to :quest, Resdayn.Codex.Dialogue.Quest do
      allow_nil? false
    end

    belongs_to :quest_version, Resdayn.Codex.Dialogue.QuestVersion do
      allow_nil? false
    end

    belongs_to :dialogue_response, Resdayn.Codex.Dialogue.Response
    belongs_to :script, Resdayn.Codex.Mechanics.Script
  end

  identities do
    identity :unique_transition,
             [
               :quest_id,
               :quest_version_id,
               :dialogue_response_id,
               :dialogue_response_topic_id,
               :script_id,
               :target_index
             ],
             nils_distinct?: false
  end
end
