defmodule Resdayn.Importer.Record do
  def of_type(records, type) when is_atom(type) do
    Enum.filter(records, &(&1.type == type))
  end

  @doc """
  Only take a subset of the available record flags - the rest appear to be vestigial
  """
  def with_flags(data, record) do
    trues =
      record.flags
      |> Map.keys()
      |> Enum.filter(fn key -> record[key] end)

    Map.put(data, :flags, trues)
  end

  defmacro __using__(_opts) do
    quote do
      import Resdayn.Importer.Record
    end
  end
end
