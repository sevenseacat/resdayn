defmodule Resdayn.Parser.Record do
  @types %{
    "TES3" => __MODULE__.MainHeader,
    "GMST" => __MODULE__.GameSetting,
    "GLOB" => __MODULE__.GlobalVariable,
    "CLAS" => __MODULE__.Class
  }

  @doc """
  Convert a record type string into a meaningful constant.
  """
  def to_module(type) do
    Map.fetch!(@types, type)
  end

  @doc "Process a collection of subrecords for this record type"
  @callback process(list) :: map

  defmacro __using__(_opts) do
    quote do
      @behaviour Resdayn.Parser.Record
      import Resdayn.Parser.{DataSizes, Helpers}
    end
  end
end
