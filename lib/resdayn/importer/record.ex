defmodule Resdayn.Importer.Record do
  def of_type(records, type) when is_atom(type) do
    Enum.filter(records, &(&1.type == type))
  end

  @doc """
  Only take a subset of the available record flags - the rest appear to be vestigial
  """
  def with_flags(data, record) do
    Map.put(data, :flags, Map.take(record.flags, [:blocked, :persistent]))
  end

  defmacro __using__(_opts) do
    quote do
      import Resdayn.Importer.Record
    end
  end
end
