defmodule Resdayn.Parser.Record.Weapon do
  use Resdayn.Parser.Record

  process_basic_string "NAME", :id
  process_basic_string "MODL", :nif_model
  process_basic_string "FNAM", :name

  def process({"WPDT", value}, data) do
    <<weight::float32(), value::uint32(), type::uint16(), health::uint16(), speed::float32(),
      reach::float32(), enchantment_points::uint16(), chop_min::uint8(), chop_max::uint8(),
      slash_min::uint8(), slash_max::uint8(), thrust_min::uint8(), thrust_max::uint8(),
      flags::uint32()>> = value

    record_unnested_value(data, %{
      weight: weight,
      value: value,
      type: type,
      health: health,
      speed: float(speed),
      reach: reach,
      enchantment_points: enchantment_points,
      chop_min: chop_min,
      chop_max: chop_max,
      slash_min: slash_min,
      slash_max: slash_max,
      thrust_min: thrust_min,
      thrust_max: thrust_max,
      flags: bitmask(flags, ignore_resistance: 1, silver: 2)
    })
  end
end
