defmodule Resdayn.Codex.Characters.Changes.ImportSkills do
  use Ash.Resource.Change

  @impl true
  def change(changeset, [type: type], _context) do
    class_id = Ash.Changeset.get_attribute(changeset, :id)
    skill_ids = Ash.Changeset.get_argument(changeset, "#{type}_skill_ids")

    relationships = Enum.map(skill_ids, &%{class_id: class_id, skill_id: &1, category: type})

    changeset
    |> Ash.Changeset.manage_relationship("#{type}_skill_relationships", relationships,
      type: :direct_control,
      on_no_match: {:create, :import}
    )
  end
end
