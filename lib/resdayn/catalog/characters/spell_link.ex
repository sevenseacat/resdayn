defmodule Resdayn.Catalog.Characters.SpellLink do
  use Ash.Resource,
    otp_app: :resdayn,
    data_layer: :embedded

  relationships do
    belongs_to :spell, Resdayn.Catalog.Mechanics.Spell,
      allow_nil?: false,
      public?: true
  end
end
