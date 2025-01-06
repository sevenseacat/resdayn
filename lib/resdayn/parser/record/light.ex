defmodule Resdayn.Parser.Record.Light do
  use Resdayn.Parser.Record

  process_basic_string "NAME", :id
  process_basic_string "MODL", :nif_model
  process_basic_string "SNAM", :sound_id
  process_basic_string "FNAM", :name
  process_basic_string "ITEX", :icon
  process_basic_string "SCRI", :script_id

  def process({"LHDT", value}, data) do
    <<weight::float32(), value::uint32(), time::int32(), radius::uint32(), color::char(4),
      flags::uint32()>> = value

    record_unnested_value(data, %{
      weight: weight,
      value: value,
      time: time,
      radius: radius,
      color: color(color),
      flags:
        bitmask(flags,
          dynamic: 0x0001,
          can_carry: 0x0002,
          negative: 0x0004,
          flicker: 0x0008,
          fire: 0x0010,
          off_by_default: 0x0020,
          flicker_slow: 0x0040,
          pulse: 0x0080,
          pulse_slow: 0x0100
        )
    })
  end
end
