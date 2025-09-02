defmodule Resdayn.Codex.Dialogue.Response do
  use Ash.Resource,
    domain: Resdayn.Codex.Dialogue,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "dialogue_responses"
    repo Resdayn.Repo

    references do
      reference :topic, on_delete: :delete
    end

    custom_indexes do
      index [:previous_response_id]
      index [:next_response_id]
      index [:id, :topic_id]
    end
  end

  actions do
    defaults [:read, :create, :update, :destroy]

    read :for_npc do
      argument :npc_id, :string, allow_nil?: false
      argument :topic, :string, allow_nil?: false

      filter expr(valid_for_npc_id(npc_id: ^arg(:npc_id)))
      filter expr(topic_id == ^arg(:topic))
    end

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

    belongs_to :speaker_npc, Resdayn.Codex.World.NPC
    belongs_to :speaker_creature, Resdayn.Codex.World.Creature
    belongs_to :speaker_class, Resdayn.Codex.Characters.Class
    belongs_to :speaker_race, Resdayn.Codex.Characters.Race
    belongs_to :speaker_faction, Resdayn.Codex.Characters.Faction

    belongs_to :player_faction, Resdayn.Codex.Characters.Faction

    has_many :cell_references, Resdayn.Codex.World.Cell.CellReference do
      no_attributes? true
      filter expr(cell.name == parent(cell_name))
    end
  end

  calculations do
    calculate :valid_for_npc?,
              :boolean,
              Resdayn.Codex.Dialogue.Calculations.NPCResponseFilter do
      argument :npc_id, :string
    end
  end
end
