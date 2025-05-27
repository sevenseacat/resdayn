defmodule Resdayn.Codex.Mechanics.MagicEffect do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Mechanics,
    data_layer: AshPostgres.DataLayer,
    extensions: [Resdayn.Codex.Importable]

  postgres do
    table "magic_effects"
    repo Resdayn.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    attribute :id, :integer, primary_key?: true, allow_nil?: false

    attribute :description, :string, allow_nil?: true
    attribute :size, :float, allow_nil?: false
    attribute :color, :color, allow_nil?: false
    attribute :speed, :float, allow_nil?: false
    attribute :base_cost, :float, allow_nil?: false
    attribute :size_cap, :float, allow_nil?: false

    attribute :icon_filename, :string, allow_nil?: false
    attribute :particle_texture_filename, :string, allow_nil?: false

    attribute :area_visual, :string, default: "VFX_DefaultArea"
    attribute :bolt_visual, :string, default: "VFX_DefaultBolt"
    attribute :casting_visual, :string, default: "VFX_DefaultCast"
    attribute :hit_visual, :string, default: "VFX_DefaultHit"

    attribute :allows_spellmaking, :boolean, allow_nil?: false
    attribute :allows_enchanting, :boolean, allow_nil?: false
    attribute :negative_light, :boolean, allow_nil?: false
  end

  relationships do
    belongs_to :game_setting, Resdayn.Codex.Mechanics.GameSetting,
      attribute_type: :string,
      allow_nil?: false

    belongs_to :skill, Resdayn.Codex.Characters.Skill,
      attribute_type: :integer,
      allow_nil?: false

    belongs_to :area_sound, Resdayn.Codex.Assets.Sound, attribute_type: :string
    belongs_to :bolt_sound, Resdayn.Codex.Assets.Sound, attribute_type: :string
    belongs_to :casting_sound, Resdayn.Codex.Assets.Sound, attribute_type: :string
    belongs_to :hit_sound, Resdayn.Codex.Assets.Sound, attribute_type: :string
  end

  calculations do
    calculate :name, :string, expr(game_setting.value[:value])
  end
end
