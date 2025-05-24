defmodule Resdayn.Codex.Characters.Changes.SaveRaceSkills do
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    skill_bonuses =
      Ash.Changeset.get_argument(changeset, :skill_bonuses)

    changeset
    |> Ash.Changeset.manage_relationship(:skill_bonuses, skill_bonuses, type: :direct_control)
  end
end
