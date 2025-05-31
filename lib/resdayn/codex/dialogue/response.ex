defmodule Resdayn.Codex.Dialogue.Response do
  use Ash.Resource,
    domain: Resdayn.Codex.Dialogue,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "dialogue_responses"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read, :create, :update, :destroy]

    default_accept [
      :id,
      :content,
      :script_content,
      :disposition,
      :speaker_faction_rank,
      :player_faction_rank,
      :gender,
      :conditions,
      :topic_id,
      :previous_response_id,
      :next_response_id,
      :speaker_npc_id,
      :speaker_creature_id,
      :speaker_class_id,
      :speaker_faction_id,
      :cell_name,
      :player_faction_id,
      :sound_filename
    ]
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false
    attribute :previous_response_id, :string
    attribute :next_response_id, :string

    attribute :cell_name, :string
    attribute :content, :string
    attribute :script_content, :string
    attribute :disposition, :integer, constraints: [min: 0]

    attribute :speaker_faction_rank, :integer, constraints: [min: 0]
    attribute :player_faction_rank, :integer, constraints: [min: 0]
    attribute :gender, __MODULE__.Gender
    attribute :sound_filename, :string

    attribute :conditions, {:array, __MODULE__.Condition}
  end

  relationships do
    belongs_to :topic, Resdayn.Codex.Dialogue.Topic,
      attribute_type: :string,
      primary_key?: true,
      allow_nil?: false

    belongs_to :speaker_npc, Resdayn.Codex.World.NPC, attribute_type: :string
    belongs_to :speaker_creature, Resdayn.Codex.World.Creature, attribute_type: :string
    belongs_to :speaker_class, Resdayn.Codex.Characters.Class, attribute_type: :string
    belongs_to :speaker_race, Resdayn.Codex.Characters.Race, attribute_type: :string
    belongs_to :speaker_faction, Resdayn.Codex.Characters.Faction, attribute_type: :string

    belongs_to :player_faction, Resdayn.Codex.Characters.Faction, attribute_type: :string
  end
end
