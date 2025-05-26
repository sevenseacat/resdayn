defmodule Resdayn.Codex.Characters.SpellLink do
  use Ash.Resource,
    otp_app: :resdayn,
    data_layer: :embedded

  relationships do
    belongs_to :spell, Resdayn.Codex.Mechanics.Spell,
      attribute_type: :string,
      allow_nil?: false,
      public?: true
  end
end
