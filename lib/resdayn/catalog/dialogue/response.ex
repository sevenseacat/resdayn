defmodule Resdayn.Catalog.Dialogue.Response do
  use Ash.Resource,
    domain: Resdayn.Catalog.Dialogue,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable]

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
    defaults [:read]

    read :for_npc do
      argument :npc_id, :string, allow_nil?: false
      argument :topic, :string, allow_nil?: false

      filter expr(valid_for_npc_id(npc_id: ^arg(:npc_id)))
      filter expr(topic_id == ^arg(:topic))
    end
  end

  attributes do
    attribute :id, Resdayn.Catalog.Types.RecordId, primary_key?: true, allow_nil?: false
    attribute :previous_response_id, :ci_string
    attribute :next_response_id, :ci_string

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
    belongs_to :topic, Resdayn.Catalog.Dialogue.Topic,
      primary_key?: true,
      allow_nil?: false

    belongs_to :speaker_npc, Resdayn.Catalog.World.NPC
    belongs_to :speaker_creature, Resdayn.Catalog.World.Creature
    belongs_to :speaker_class, Resdayn.Catalog.Characters.Class
    belongs_to :speaker_race, Resdayn.Catalog.Characters.Race
    belongs_to :speaker_faction, Resdayn.Catalog.Characters.Faction

    belongs_to :player_faction, Resdayn.Catalog.Characters.Faction

    has_many :cell_references, Resdayn.Catalog.World.Cell.CellReference do
      no_attributes? true
      filter expr(cell.name == parent(cell_name))
    end
  end

  calculations do
    calculate :valid_for_npc?,
              :boolean,
              Resdayn.Catalog.Dialogue.Calculations.NPCResponseFilter do
      argument :npc_id, :string
    end
  end
end
