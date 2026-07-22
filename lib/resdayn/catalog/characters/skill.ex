defmodule Resdayn.Catalog.Characters.Skill do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.Characters,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Catalog.Importable]

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

    attribute :specialization, Resdayn.Catalog.Characters.Specialization, allow_nil?: false
  end

  relationships do
    belongs_to :attribute, Resdayn.Catalog.Mechanics.Attribute,
      allow_nil?: false,
      attribute_type: :integer

    # The NPCs who can train this skill, best first: skill values whose skill is
    # one of the NPC's 3 highest. `limit` is honored because loading a relationship
    # uses a lateral join — so loading it across every skill is one query, not an N+1.
    has_many :trainers, Resdayn.Catalog.World.NPC.SkillValue do
      filter expr(skill_id in npc.trained_skill_ids)
      sort value: :desc
      limit 5
    end
  end
end
