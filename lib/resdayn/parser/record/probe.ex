defmodule Resdayn.Parser.Record.Probe do
  use Resdayn.Parser.Record

  process_basic_string "NAME", :id
  process_basic_string "MODL", :nif_model
  process_basic_string "FNAM", :name
  process_basic_string "ITEX", :icon
  process_basic_string "SCRI", :script_id

  def process({"PBDT", value}, data) do
    <<weight::float32(), value::uint32(), quality::float32(), uses::uint32()>> = value

    record_unnested_value(data, %{weight: weight, value: value, quality: quality, uses: uses})
  end
end
