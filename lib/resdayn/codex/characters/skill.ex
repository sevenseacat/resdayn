defmodule Resdayn.Codex.Characters.Skill do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Characters,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "skills"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, :integer, primary_key?: true, allow_nil?: false

    attribute :name, :string, allow_nil?: false
    attribute :description, :string, allow_nil?: false

    attribute :uses, {:array, :float},
      allow_nil?: false,
      constraints: [min_length: 4, max_length: 4]

    attribute :specialization, Resdayn.Codex.Characters.Specialization, allow_nil?: false
  end

  relationships do
    belongs_to :attribute, Resdayn.Codex.Mechanics.Attribute,
      allow_nil?: false,
      attribute_type: :integer
  end
end
