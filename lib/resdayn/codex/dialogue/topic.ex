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
  end

  attributes do
    attribute :id, :string, primary_key?: true, allow_nil?: false
    attribute :type, __MODULE__.Type, allow_nil?: false
  end

  # relationships do
  #   has_many :responses, Resdayn.Codex.Dialogue.Response
  # end
end
