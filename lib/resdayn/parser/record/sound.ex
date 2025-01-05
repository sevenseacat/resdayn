defmodule Resdayn.Parser.Record.Sound do
  use Resdayn.Parser.Record

  def process({"NAME" = v, value}, data) do
    record_value(data, :id, printable!(__MODULE__, v, value))
  end

  def process({"FNAM" = v, value}, data) do
    record_value(data, :filename, printable!(__MODULE__, v, value))
  end

  def process({"DATA", value}, data) do
    <<volume::integer, min_range::integer, max_range::integer>> = value

    record_value(data, :attenuation, %{volume: volume, min_range: min_range, max_range: max_range})
  end
end
