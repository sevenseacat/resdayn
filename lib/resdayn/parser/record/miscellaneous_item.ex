defmodule Resdayn.Parser.Record.MiscellaneousItem do
  use Resdayn.Parser.Record

  process_basic_string "NAME", :id
  process_basic_string "MODL", :nif_model
  process_basic_string "FNAM", :name
  process_basic_string "ITEX", :icon_filename

  def process({"MCDT", value}, data) do
    <<weight::lfloat(), value::long(), _::binary>> = value
    record_unnested_value(data, %{weight: float(weight), value: value})
  end
end
