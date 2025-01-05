defmodule Resdayn.Parser.Record.GlobalVariable do
  @moduledoc """
  Contains a single NAME record, a FNAM value type, and a FLTV float record
  The FLTV could be an integer, a long, or a float :(
  """
  use Resdayn.Parser.Record

  process_basic_string "NAME", :name
  process_basic_string "FNAM", :type

  def process({"FLTV", value}, %{type: "s"} = data) do
    record_value(data, :value, float_to_short(value))
  end

  def process({"FLTV", <<value::uint32()>>}, %{type: "l"} = data) do
    record_value(data, :value, value)
  end

  def process({"FLTV", <<value::float32()>>}, %{type: "f"} = data) do
    record_value(data, :value, value)
  end
end
