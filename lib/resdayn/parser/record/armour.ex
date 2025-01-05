defmodule Resdayn.Parser.Record.Armour do
  use Resdayn.Parser.Record

  @armour_types %{
    0 => :helmet,
    1 => :cuirass,
    2 => :left_pauldron,
    3 => :right_pauldron,
    4 => :greaves,
    5 => :boots,
    6 => :left_gauntlet,
    7 => :right_gauntlet,
    8 => :shield,
    9 => :left_bracer,
    10 => :right_bracer
  }

  process_basic_string "NAME", :id
  process_basic_string "MODL", :nif_model
  process_basic_string "FNAM", :name
  process_basic_string "ITEX", :icon
  process_basic_string "SCRI", :script_id
  process_body_coverings()

  def process({"AODT", value}, data) do
    <<type::uint32(), weight::float32(), value::uint32(), health::uint32(),
      enchantment_points::uint32(), armour_rating::uint32()>> = value

    record_unnested_value(data, %{
      type: Map.fetch!(@armour_types, type),
      weight: weight,
      value: value,
      health: health,
      enchantment_points: enchantment_points,
      armour_rating: armour_rating
    })
  end
end
