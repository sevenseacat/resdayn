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

  attributes do
    attribute :id, :integer, primary_key?: true, allow_nil?: false, public?: true

    attribute :description, :string, allow_nil?: true, public?: true
    attribute :size, :float, allow_nil?: false, public?: true
    attribute :color, :color, allow_nil?: false, public?: true
    attribute :speed, :float, allow_nil?: false, public?: true
    attribute :base_cost, :float, allow_nil?: false, public?: true
    attribute :size_cap, :float, allow_nil?: false, public?: true

    attribute :icon_filename, :string, allow_nil?: false, public?: true
    attribute :particle_texture_filename, :string, allow_nil?: false, public?: true

    attribute :area_visual, :string, default: "VFX_DefaultArea", public?: true
    attribute :bolt_visual, :string, default: "VFX_DefaultBolt", public?: true
    attribute :casting_visual, :string, default: "VFX_DefaultCast", public?: true
    attribute :hit_visual, :string, default: "VFX_DefaultHit", public?: true

    attribute :allows_spellmaking, :boolean, allow_nil?: false, public?: true
    attribute :allows_enchanting, :boolean, allow_nil?: false, public?: true
    attribute :negative_light, :boolean, allow_nil?: false, public?: true

    attribute :flags, Resdayn.Codex.Flags, allow_nil?: false, public?: true
  end

  relationships do
    belongs_to :game_setting, Resdayn.Codex.Mechanics.GameSetting,
      attribute_type: :string,
      destination_attribute: :name,
      allow_nil?: false,
      public?: true

    belongs_to :skill, Resdayn.Codex.Characters.Skill,
      attribute_type: :integer,
      allow_nil?: false,
      public?: true

    belongs_to :area_sound, Resdayn.Codex.Assets.Sound, attribute_type: :string, public?: true
    belongs_to :bolt_sound, Resdayn.Codex.Assets.Sound, attribute_type: :string, public?: true
    belongs_to :casting_sound, Resdayn.Codex.Assets.Sound, attribute_type: :string, public?: true
    belongs_to :hit_sound, Resdayn.Codex.Assets.Sound, attribute_type: :string, public?: true
  end

  aggregates do
    first :name, :game_setting, :value
  end
end
