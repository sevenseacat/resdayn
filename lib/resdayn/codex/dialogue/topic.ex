defmodule Resdayn.Codex.Dialogue.Topic do
  use Ash.Resource,
    domain: Resdayn.Codex.Dialogue,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "dialogue_topics"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]

    read :for_npc do
      argument :npc_id, :string, allow_nil?: false
      filter expr(exists(responses, valid_for_npc?(npc_id: ^arg(:npc_id))))
    end

    read :get_with_responses do
      get? true

      argument :id, :string, allow_nil?: false
      argument :npc_id, :string

      filter expr(id == ^arg(:id))

      prepare fn query, _context ->
        case Ash.Query.get_argument(query, :npc_id) do
          nil ->
            Ash.Query.load(query, :ordered_responses)

          npc_id ->
            Ash.Query.after_action(query, fn _query, results ->
              filtered_results =
                Enum.map(results, fn topic ->
                  topic
                  |> Ash.load!(ordered_responses: [valid_for_npc?: [npc_id: npc_id]])
                  |> Map.update!(:ordered_responses, fn responses ->
                    Enum.filter(responses, & &1.valid_for_npc?)
                  end)
                end)

              {:ok, filtered_results}
            end)
        end
      end
    end

    update :import_relationships do
      require_atomic? false
      accept [:source_file_ids]
      argument :responses, {:array, :map}, allow_nil?: false, default: []

      change {Resdayn.Codex.Changes.OptimizedRelationshipImport,
              argument: :responses,
              relationship: :responses,
              related_resource: Resdayn.Codex.Dialogue.Response,
              parent_key: :topic_id,
              id_field: :id,
              on_missing: :ignore}
    end
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false
    attribute :type, __MODULE__.Type, allow_nil?: false
  end

  relationships do
    has_many :responses, Resdayn.Codex.Dialogue.Response

    has_many :ordered_responses, Resdayn.Codex.Dialogue.Response do
      manual Resdayn.Codex.Dialogue.OrderedResponseRelationship
    end
  end
end
