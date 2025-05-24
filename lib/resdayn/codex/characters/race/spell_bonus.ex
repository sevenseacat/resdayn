defmodule Resdayn.Codex.Characters.Race.SpellBonus do
  use Ash.Resource,
    otp_app: :resdayn,
    data_layer: :embedded

  attributes do
    attribute :spell_id, :string, allow_nil?: false, public?: true
  end

  relationships do
    belongs_to :spell, Resdayn.Codex.Mechanics.Spell,
      attribute_type: :string,
      allow_nil?: false,
      public?: true
  end
end