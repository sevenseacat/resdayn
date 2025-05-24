defmodule Resdayn.Codex.Characters.Race.SpellBonus do
  use Ash.Resource,
    otp_app: :resdayn,
    domain: Resdayn.Codex.Characters,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "race_spell_bonuses"
    repo Resdayn.Repo

    references do
      reference :race, on_delete: :delete
      reference :spell, on_delete: :delete
    end
  end

  actions do
    default_accept [:race_id, :spell_id]
    defaults [:read, :create, :update, :destroy]
  end

  relationships do
    belongs_to :race, Resdayn.Codex.Characters.Race,
      primary_key?: true,
      allow_nil?: false,
      attribute_type: :string

    belongs_to :spell, Resdayn.Codex.Mechanics.Spell,
      primary_key?: true,
      allow_nil?: false,
      attribute_type: :string
  end
end