defmodule Resdayn.Parser.Record.GlobalVariable do
  import Resdayn.Parser.{DataSizes, Helpers}

  @doc """
  Contains a single NAME record, a FNAM value type, and a FLTV float record
  The FLTV could be an integer, a long, or a float :(
  """
  def process([{"NAME", name}, {"FNAM", type}, {"FLTV", value}]) do
    %{
      name: printable!(__MODULE__, "NAME", name),
      type: type,
      value: parse(type, value)
    }
  end

  defp parse("s", value), do: float_to_short(value)
  defp parse("l", <<value::long()>>), do: value
  defp parse("f", <<value::lfloat()>>), do: value
end
