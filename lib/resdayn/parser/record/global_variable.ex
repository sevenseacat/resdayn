defmodule Resdayn.Parser.Record.GlobalVariable do
  @moduledoc """
  Contains a single NAME record, a FNAM value type, and a FLTV float record
  The FLTV could be an integer, a long, or a float :(
  """
  use Resdayn.Parser.Record

  def process({"NAME" = v, value}, data) do
    record_value(data, :name, printable!(__MODULE__, v, value))
  end

  def process({"FNAM", value}, data) do
    record_value(data, :type, value)
  end

  def process({"FLTV", value}, %{type: "s"} = data) do
    record_value(data, :value, float_to_short(value))
  end

  def process({"FLTV", <<value::long()>>}, %{type: "l"} = data) do
    record_value(data, :value, value)
  end

  def process({"FLTV", <<value::lfloat()>>}, %{type: "f"} = data) do
    record_value(data, :value, value)
  end
end
