defmodule Resdayn.Codex.Changes.DeleteReferencableObject do
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    # Run after the specialized resource is destroyed
    Ash.Changeset.after_action(changeset, fn _changeset, record ->
      # Delete the corresponding ReferencableObject
      Resdayn.Codex.World.ReferencableObject
      |> Ash.get!(record.id)
      |> Ash.destroy!(return_notifications?: true)

      {:ok, record}
    end)
  end
end
