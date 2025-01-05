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

  @body_parts %{
    0 => :head,
    1 => :hair,
    2 => :neck,
    3 => :cuirass,
    4 => :groin,
    5 => :skirt,
    6 => :right_hand,
    7 => :left_hand,
    8 => :right_wrist,
    9 => :left_wrist,
    10 => :shield,
    11 => :right_forearm,
    12 => :left_forearm,
    13 => :right_upper_arm,
    14 => :left_upper_arm,
    15 => :right_foot,
    16 => :left_foot,
    17 => :right_ankle,
    18 => :left_ankle,
    19 => :right_knee,
    20 => :left_knee,
    21 => :right_upper_leg,
    22 => :left_upper_leg,
    23 => :right_pauldron,
    24 => :left_pauldron,
    25 => :weapon,
    26 => :tail
  }

  process_basic_string "NAME", :id
  process_basic_string "MODL", :nif_model
  process_basic_string "FNAM", :name
  process_basic_string "ITEX", :icon
  process_basic_string "SCRI", :script_id

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

  def process({"INDX", <<value::uint8()>>}, data) do
    record_list_of_maps_key(data, :body_parts, :type, Map.fetch!(@body_parts, value))
  end

  def process({"BNAM" = v, value}, data) do
    record_list_of_maps_value(data, :body_parts, :male_name, printable!(__MODULE__, v, value))
  end
end
