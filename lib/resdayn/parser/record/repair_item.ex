defmodule Resdayn.Parser.Record.RepairItem do
  use Resdayn.Parser.Record

  process_basic_string "NAME", :id
  process_basic_string "MODL", :nif_model
  process_basic_string "FNAM", :name
  process_basic_string "ITEX", :icon
  process_basic_string "SCRI", :script_id

  def process({"RIDT", value}, data) do
    <<weight::float32(), value::uint32(), uses::uint32(), quality::float32()>> = value

    record_unnested_value(data, %{
      weight: weight,
      value: value,
      uses: uses,
      quality: float(quality)
    })
  end
end
