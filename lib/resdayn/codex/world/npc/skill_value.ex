defmodule Resdayn.Codex.World.NPC.SkillValue do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.World,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "npc_skill_values"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :value, :integer, allow_nil?: false, constraints: [min: 0], public?: true
  end

  relationships do
    belongs_to :npc, Resdayn.Codex.World.NPC,
      primary_key?: true,
      allow_nil?: false,
      attribute_type: :string

    belongs_to :skill, Resdayn.Codex.Characters.Skill,
      primary_key?: true,
      allow_nil?: false,
      attribute_type: :integer
  end
end
