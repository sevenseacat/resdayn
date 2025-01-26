defmodule Resdayn.Importer.Record do
  def of_type(records, type) when is_atom(type) do
    Enum.filter(records, &(&1.type == type))
  end

  defmacro __using__(_opts) do
    quote do
      import Resdayn.Importer.Record
    end
  end
end
