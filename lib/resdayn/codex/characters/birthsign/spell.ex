defmodule Resdayn.Codex.Characters.Birthsign.Spell do
  use Ash.Resource,
    otp_app: :resdayn,
    data_layer: :embedded

  attributes do
  end

  relationships do
    belongs_to :spell, Resdayn.Codex.Mechanics.Spell,
      attribute_type: :string,
      allow_nil?: false,
      public?: true
  end
end
