defmodule Resdayn.Parser.Record.Weapon do
  use Resdayn.Parser.Record

  @weapon_types %{
    0 => :short_blade,
    1 => :long_blade_1_hand,
    2 => :long_blade_2_hand,
    3 => :blunt_1_hand,
    4 => :blunt_2_hand_close,
    5 => :blunt_2_hand_wide,
    6 => :spear,
    7 => :axe_1_hand,
    8 => :axe_2_hand,
    9 => :bow,
    10 => :crossbow,
    11 => :thrown,
    12 => :arrow,
    13 => :bolt
  }

  process_basic_string "NAME", :id
  process_basic_string "MODL", :nif_model_filename
  process_basic_string "FNAM", :name
  process_basic_string "ITEX", :icon_filename
  process_basic_string "ENAM", :enchantment_id
  process_basic_string "SCRI", :script_id

  def process({"WPDT", value}, data) do
    <<weight::float32(), value::uint32(), type::uint16(), health::uint16(), speed::float32(),
      reach::float32(), enchantment_points::uint16(), chop_min::uint8(), chop_max::uint8(),
      slash_min::uint8(), slash_max::uint8(), thrust_min::uint8(), thrust_max::uint8(),
      flags::uint32()>> = value

    record_unnested_value(data, %{
      weight: float(weight),
      value: value,
      type: Map.fetch!(@weapon_types, type),
      health: health,
      speed: float(speed),
      reach: float(reach),
      enchantment_points: enchantment_points,
      chop_magnitude: %{min: chop_min, max: chop_max},
      slash_magnitude: %{min: slash_min, max: slash_max},
      thrust_magnitude: %{min: thrust_min, max: thrust_max},
      flags: bitmask(flags, ignore_resistance: 1, silver: 2)
    })
  end
end
