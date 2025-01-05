defmodule Resdayn.Parser.Record.Sound do
  use Resdayn.Parser.Record

  process_basic_string "NAME", :id
  process_basic_string "FNAM", :filename

  def process({"DATA", value}, data) do
    <<volume::integer, min_range::integer, max_range::integer>> = value

    record_value(data, :attenuation, %{volume: volume, min_range: min_range, max_range: max_range})
  end
end
