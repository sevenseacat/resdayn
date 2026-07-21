defmodule Resdayn.Catalog.World.NPC.SkillValue do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Catalog.World,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "npc_skill_values"
    repo Resdayn.Repo
  end

  @base_game_files ["Morrowind.esm", "Tribunal.esm", "Bloodmoon.esm"]

  actions do
    defaults [:read]
  end

  attributes do
    attribute :value, :integer, allow_nil?: false, constraints: [min: 0], public?: true
  end

  calculations do
    # An NPC can train a skill when they offer training and it's one of their 3
    # highest skills. `highest_skill_values` is that top-3 set — and `exists`
    # honors its `limit` because the relationship is a single-hop FK self-join.
    calculate :trainable?,
              :boolean,
              expr(
                :training in npc.services_offered and
                  exists(highest_skill_values, skill_id == parent(skill_id))
              )

    calculate :from_base_game?,
              :boolean,
              expr(fragment("? && ?", npc.source_file_ids, ^@base_game_files))
  end

  relationships do
    belongs_to :npc, Resdayn.Catalog.World.NPC,
      primary_key?: true,
      allow_nil?: false

    belongs_to :skill, Resdayn.Catalog.Characters.Skill,
      primary_key?: true,
      allow_nil?: false,
      attribute_type: :integer

    # The NPC's 3 highest skills — the ones they can train. Self-joined on npc_id
    # (a real FK-style correlation, not a `parent()` filter) so the `limit` is
    # honored when this is used inside `exists` in `trainers_for_skill`.
    has_many :highest_skill_values, __MODULE__ do
      public? false
      source_attribute :npc_id
      destination_attribute :npc_id
      sort value: :desc, skill_id: :asc
      limit 3
    end
  end
end
