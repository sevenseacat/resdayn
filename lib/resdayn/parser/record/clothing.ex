defmodule Resdayn.Parser.Record.Clothing do
  use Resdayn.Parser.Record

  @clothing_types %{
    0 => :pants,
    1 => :shoes,
    2 => :shirt,
    3 => :belt,
    4 => :robe,
    5 => :right_glove,
    6 => :left_glove,
    7 => :skirt,
    8 => :ring,
    9 => :amulet
  }

  process_basic_string "NAME", :id
  process_basic_string "MODL", :nif_model
  process_basic_string "FNAM", :name
  process_basic_string "ITEX", :icon
  process_basic_string "ENAM", :enchantment
  process_basic_string "SCRI", :script_id
  process_body_coverings()

  def process({"CTDT", value}, data) do
    <<type::uint32(), weight::float32(), value::uint16(), enchantment_points::uint16()>> = value

    record_unnested_value(data, %{
      type: Map.fetch!(@clothing_types, type),
      weight: weight,
      value: value,
      enchantment_points: enchantment_points
    })
  end
end
