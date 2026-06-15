defmodule Resdayn.Catalog.Changes.CreateOverride do
  use Ash.Resource.Change

  @impl true
  def init(opts) do
    case Keyword.get(opts, :resource_type) do
      nil -> {:error, "resource_type option is required"}
      type when is_atom(type) -> {:ok, opts}
      _ -> {:error, "resource_type must be an atom"}
    end
  end

  @impl true
  def atomic(_changeset, _opts, _context), do: :not_atomic

  @impl true
  def change(changeset, opts, _context) do
    Ash.Changeset.after_action(changeset, fn _changeset, record ->
      resource_type = Keyword.fetch!(opts, :resource_type)

      Resdayn.Catalog.Export.Override
      |> Ash.Changeset.for_create(:create, %{
        record_id: to_string(record.id),
        resource_type: resource_type
      })
      |> Ash.create!()

      update_search_index(record, resource_type)

      {:ok, record}
    end)
  end

  defp update_search_index(record, resource_type) do
    name = Map.get(record, :name)

    if is_binary(name) and name != "" do
      Resdayn.Catalog.Search.SearchIndex
      |> Ash.Changeset.for_create(:upsert, %{
        id: "#{resource_type}:#{record.id}",
        name: name,
        type: resource_type,
        icon_filename: Map.get(record, :icon_filename)
      })
      |> Ash.create!()
    end
  end
end
