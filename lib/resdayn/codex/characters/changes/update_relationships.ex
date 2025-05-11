defmodule Resdayn.Codex.Characters.Changes.UpdateRelationships do
  use Ash.Resource.Change

  @impl true
  def change(changeset, opts, _context) do
    changeset
    |> Ash.Changeset.after_action(fn changeset, record ->
      relationships = Map.take(changeset.arguments, opts[:arguments])

      {record, notifications} =
        record
        |> Ash.Changeset.for_update(:update, relationships)
        |> Ash.update!(return_notifications?: true)

      {:ok, record, notifications}
    end)
  end
end
