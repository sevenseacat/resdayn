defmodule Resdayn.Parser.Record do
  @types %{
    "TES3" => __MODULE__.MainHeader,
    "GMST" => __MODULE__.GameSetting,
    "GLOB" => __MODULE__.GlobalVariable
  }

  @doc """
  Convert a record type string into a meaningful constant.
  """
  def to_module(type) do
    Map.fetch!(@types, type)
  end
end
