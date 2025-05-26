defmodule Resdayn.Codex.Characters.SkillValue do
  use Ash.Resource,
    otp_app: :resdayn,
    data_layer: :embedded

  attributes do
    attribute :value, :integer, allow_nil?: false, constraints: [min: 0], public?: true
  end

  relationships do
    belongs_to :skill, Resdayn.Codex.Mechanics.Skill,
      attribute_type: :integer,
      allow_nil?: false,
      public?: true
  end
end
