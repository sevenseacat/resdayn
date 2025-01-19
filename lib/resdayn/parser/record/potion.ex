defmodule Resdayn.Parser.Record.Potion do
  use Resdayn.Parser.Record

  process_basic_string "NAME", :id
  process_basic_string "MODL", :nif_model
  process_basic_string "TEXT", :icon
  process_basic_string "FNAM", :name
  process_basic_string "SCRI", :script_id
  process_enchantments "ENAM", :effects

  def process({"ALDT", value}, data) do
    <<weight::float32(), value::uint32(), flags::uint32()>> = value

    record_unnested_value(data, %{
      weight: float(weight),
      value: value,
      flags: bitmask(flags, autocalc: 0x1)
    })
  end
end
