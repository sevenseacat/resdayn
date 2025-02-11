defmodule Resdayn.Importer.Record do
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

  defmacro __using__(_opts) do
    quote do
      import Resdayn.Importer.Record
    end
  end
end
