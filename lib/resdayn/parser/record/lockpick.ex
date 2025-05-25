defmodule Resdayn.Parser.Record.Lockpick do
  use Resdayn.Parser.Record

  process_basic_string "NAME", :id
  process_basic_string "MODL", :nif_model_filename
  process_basic_string "FNAM", :name
  process_basic_string "ITEX", :icon_filename
  process_basic_string "SCRI", :script_id

  def process({"LKDT", value}, data) do
    <<weight::float32(), value::uint32(), quality::float32(), uses::uint32()>> = value

    record_unnested_value(data, %{
      weight: weight,
      value: value,
      quality: float(quality),
      uses: uses
    })
  end
end
