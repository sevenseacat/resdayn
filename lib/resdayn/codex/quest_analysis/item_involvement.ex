defmodule Resdayn.Codex.QuestAnalysis.ItemInvolvement do
  @moduledoc """
  An involvement row linking an item-shaped `ReferencableObject` (weapon, book,
  ingredient, container, …) to a quest, with a reason explaining how the
  object participates in the quest and a reference to the source record that
  surfaced the involvement.

  Structurally a near-clone of `ActorInvolvement`, but with a single
  `object_id` FK instead of an NPC/creature XOR — the codex's unified
  `ReferencableObject` table is the polymorphic anchor for every addressable
  in-game entity, so the concrete typed resource (Weapon, Book, …) is reached
  via the `:object` relationship's `TypedObject` calc when display needs it.

  The source XOR mirrors `ActorInvolvement`: exactly one of
  (dialogue_response + topic_id) / script_id is set.
  """

  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.QuestAnalysis,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "item_involvements"
    repo Resdayn.Repo

    references do
      reference :quest, on_delete: :delete
      reference :quest_version, on_delete: :delete
      reference :object, on_delete: :delete
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
        :reason,
        :quest_id,
        :quest_version_id,
        :object_id,
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

    attribute :dialogue_response_topic_id, :ci_string
  end

  relationships do
    belongs_to :quest, Resdayn.Codex.Dialogue.Quest do
      allow_nil? false
    end

    belongs_to :quest_version, Resdayn.Codex.Dialogue.QuestVersion do
      allow_nil? false
    end

    belongs_to :object, Resdayn.Codex.World.ReferencableObject do
      allow_nil? false
    end

    belongs_to :dialogue_response, Resdayn.Codex.Dialogue.Response
    belongs_to :script, Resdayn.Codex.Mechanics.Script
  end

  calculations do
    # Resolves the polymorphic :object (ReferencableObject) to its concrete
    # typed resource (Weapon, Book, …) so display has a name, icon and link.
    calculate :typed_object, :struct, {Resdayn.Codex.Calculations.TypedObject, field: :object}
  end

  identities do
    identity :unique_involvement,
             [
               :quest_id,
               :quest_version_id,
               :object_id,
               :reason,
               :dialogue_response_id,
               :dialogue_response_topic_id,
               :script_id
             ],
             nils_distinct?: false
  end
end
