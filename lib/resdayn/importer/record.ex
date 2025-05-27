defmodule Resdayn.Importer.Record do
  require Ash.Query

  def of_type(records, type) when is_atom(type) do
    Enum.filter(records, &(&1.type == type))
  end

  @doc """
  Only take a subset of the available record flags - the rest appear to be vestigial
  """
  def with_flags(data, key, flags) do
    trues =
      flags
      |> Map.keys()
      |> Enum.filter(fn key -> flags[key] end)

    Map.put(data, key, trues)
  end

  def find_existing(resource, records) do
    ids = Enum.map(records, & &1.id)

    resource
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(id in ^ids)
    |> Ash.read!()
    |> Map.new(&{&1.id, &1})
  end

  def separate_for_import(records, resource, opts \\ []) do
    existing = find_existing(resource, records)

    update_action = Keyword.get(opts, :action, :import_update)

    Enum.reduce(records, %{resource: resource, create: [], update: []}, fn record, acc ->
      if match = Map.get(existing, record.id) do
        changeset = Ash.Changeset.for_update(match, update_action, Map.drop(record, [:id]))
        Map.update!(acc, :update, &[changeset | &1])
      else
        Map.update!(acc, :create, &[record | &1])
      end
    end)
  end

  defmacro __using__(_opts) do
    quote do
      import Resdayn.Importer.Record
    end
  end
end
