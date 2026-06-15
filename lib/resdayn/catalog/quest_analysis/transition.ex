defmodule Resdayn.Catalog.QuestAnalysis.Transition do
  @moduledoc """
  A `Journal "QuestID" N` call site — the atom of quest state changes.

  Each row records the source (a dialogue response or a standalone script)
  that contains the call and the `target_index` the call advances the quest
  to. Transitions are the edges of the quest state machine — see
  `docs/quest-analyzer-v4.md` §4.4.

  Discovery populates the bare fields (source + `target_index`). Later passes
  fill in:

  - `from_min` / `from_max` — the journal range this transition can fire from,
    derived from `:journal` conditions on the source and then narrowed to the
    quest's known journal indices.
  - `flags` — edge-level roles (currently `:start`). Finish and restart are
    properties of the journal entry, not the transition, so they live on
    `JournalEntry`.

  Source XOR mirrors `ActorInvolvement` / `ItemInvolvement`: exactly one
  of `(dialogue_response_id + dialogue_response_topic_id)` / `script_id`
  is set.
  """

  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.QuestAnalysis,
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
        :script_id,
        :from_min,
        :from_max,
        :flags
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

    # Filled by later passes.
    attribute :from_min, :integer
    attribute :from_max, :integer

    attribute :flags, {:array, Resdayn.Catalog.QuestAnalysis.Transition.Flag} do
      allow_nil? false
      default []
    end
  end

  relationships do
    belongs_to :quest, Resdayn.Catalog.Dialogue.Quest do
      allow_nil? false
    end

    belongs_to :quest_version, Resdayn.Catalog.Dialogue.QuestVersion do
      allow_nil? false
    end

    belongs_to :dialogue_response, Resdayn.Catalog.Dialogue.Response

    belongs_to :dialogue_topic, Resdayn.Catalog.Dialogue.Topic,
      source_attribute: :dialogue_response_topic_id

    belongs_to :script, Resdayn.Catalog.Mechanics.Script
  end
end
