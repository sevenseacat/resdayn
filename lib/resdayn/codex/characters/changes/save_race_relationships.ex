defmodule Resdayn.Codex.Characters.Changes.SaveRaceRelationships do
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    skill_bonuses = Ash.Changeset.get_argument(changeset, :skill_bonuses) || []
    special_spell_ids = Ash.Changeset.get_argument(changeset, :special_spell_ids) || []

    # Transform skill bonuses for manage_relationship
    skill_bonus_relationships = Enum.map(skill_bonuses, fn bonus ->
      %{skill_id: bonus.skill_id, bonus: bonus.bonus}
    end)



    changeset
    |> Ash.Changeset.manage_relationship(:skill_bonuses, skill_bonus_relationships,
      type: :direct_control
    )
    |> Ash.Changeset.manage_relationship(:special_spells, special_spell_ids,
      type: :append_and_remove
    )
  end
end