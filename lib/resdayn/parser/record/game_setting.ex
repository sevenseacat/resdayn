defmodule Resdayn.Parser.Record.GameSetting do
  @moduledoc """
  Contains a single NAME record, then either a STRV, INTV or FLTV record.
  """
  use Resdayn.Parser.Record

  def process({"NAME" = v, value}, data) do
    record_value(data, :name, printable!(__MODULE__, v, value))
  end

  def process({"STRV" = v, value}, data) do
    record_value(data, :value, printable!(__MODULE__, v, value))
  end

  def process({"FLTV", <<value::lfloat()>>}, data) do
    record_value(data, :value, Float.round(value, 2))
  end

  def process({"INTV", <<value::int()>>}, data) do
    record_value(data, :value, value)
  end
end
