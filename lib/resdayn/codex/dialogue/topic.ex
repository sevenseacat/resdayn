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
      filter expr(exists(responses, valid_for_npc_id(npc_id: ^arg(:npc_id))))
    end

    update :import_relationships do
      require_atomic? false
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
  end
end
