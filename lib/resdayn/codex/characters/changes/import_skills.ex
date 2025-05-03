defmodule Resdayn.Codex.Characters.Changes.ImportSkills do
  use Ash.Resource.Change

  @impl true
  def change(changeset, [type: type], _context) do
    skill_ids =
      Ash.Changeset.get_argument(changeset, String.to_existing_atom("#{type}_skill_ids"))

    relationships = Enum.map(skill_ids, &%{skill_id: &1, category: type})

    changeset
    |> Ash.Changeset.manage_relationship("#{type}_skill_relationships", relationships,
      type: :direct_control,
      on_no_match: {:create, :import}
    )
  end
end
