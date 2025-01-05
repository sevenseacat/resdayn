defmodule Resdayn.Parser.Record.GameSetting do
  @moduledoc """
  Contains a single NAME record, then either a STRV, INTV or FLTV record.
  """
  use Resdayn.Parser.Record

  process_basic_string "NAME", :name
  process_basic_string "STRV", :value

  def process({"FLTV", <<value::lfloat()>>}, data) do
    record_value(data, :value, float(value))
  end

  def process({"INTV", <<value::int()>>}, data) do
    record_value(data, :value, value)
  end
end
