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

    read :trainers_for_skill do
      argument :skill_id, :integer, allow_nil?: false
      argument :base_game_only, :boolean, default: false

      filter expr(skill_id == ^arg(:skill_id) and :training in npc.services_offered)

      filter expr(
               not (^arg(:base_game_only)) or
                 fragment(
                   "? && ?",
                   npc.source_file_ids,
                   ^["Morrowind.esm", "Tribunal.esm", "Bloodmoon.esm"]
                 )
             )

      prepare build(sort: [value: :desc], limit: 3, load: [npc: [:source_file_ids]])
    end
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
