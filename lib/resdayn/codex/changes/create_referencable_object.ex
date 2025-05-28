defmodule Resdayn.Codex.Changes.CreateReferencableObject do
  use Ash.Resource.Change

  @impl true
  def init(opts) do
    # Validate that object_type is provided
    case Keyword.get(opts, :object_type) do
      nil -> {:error, "object_type option is required"}
      type when is_atom(type) -> {:ok, opts}
      _ -> {:error, "object_type must be an atom"}
    end
  end

  @impl true
  def change(changeset, opts, _context) do
    # Only run for import_create actions
    Ash.Changeset.before_action(changeset, fn changeset ->
      id = Ash.Changeset.get_attribute(changeset, :id)
      object_type = Keyword.get(opts, :object_type)

      # Create ReferencableObject entry before the specialized resource
      Resdayn.Codex.World.ReferencableObject
      |> Ash.Changeset.for_create(:create, %{
        id: id,
        type: object_type
      })
      |> Ash.create!(return_notifications?: true)

      changeset
    end)
  end
end
