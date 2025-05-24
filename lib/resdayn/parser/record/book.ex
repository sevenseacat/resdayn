defmodule Resdayn.Parser.Record.Book do
  use Resdayn.Parser.Record

  process_basic_string "NAME", :id
  process_basic_string "MODL", :nif_model_filename
  process_basic_string "FNAM", :name
  process_basic_string "ITEX", :icon_filename
  process_basic_string "TEXT", :content
  process_basic_string "SCRI", :script_id
  process_basic_string "ENAM", :enchantment_id

  def process({"BKDT", value}, data) do
    <<weight::float32(), value::uint32(), flags::uint32(), skill_id::int32(),
      enchantment_points::uint32()>> = value

    record_unnested_value(data, %{
      weight: float(weight),
      value: value,
      flags: bitmask(flags, scroll: 0x1),
      skill_id: nil_if_negative(skill_id),
      enchantment_points: enchantment_points
    })
  end
end
