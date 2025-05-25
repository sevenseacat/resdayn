defmodule Resdayn.Parser.Record.BodyPart do
  use Resdayn.Parser.Record

  @body_part_types %{
    0 => :head,
    1 => :hair,
    2 => :neck,
    3 => :chest,
    4 => :groin,
    5 => :hand,
    6 => :wrist,
    7 => :forearm,
    8 => :upper_arm,
    9 => :foot,
    10 => :ankle,
    11 => :knee,
    12 => :upper_leg,
    13 => :clavicle,
    14 => :tail
  }

  @body_part_coverables %{
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

  @equipment_types %{
    0 => :skin,
    1 => :clothing,
    2 => :armour
  }

  process_basic_string "NAME", :id
  process_basic_string "MODL", :nif_model_filename
  process_basic_string "FNAM", :race_id

  def process({"BYDT", value}, data) do
    <<type::uint8(), vampire::uint8(), flags::uint8(), equipment_type::uint8()>> = value

    record_unnested_value(data, %{
      type: Map.fetch!(@body_part_types, type),
      vampire: vampire == 1,
      flags: bitmask(flags, female: 0x1, playable: 0x2),
      equipment_type: Map.fetch!(@equipment_types, equipment_type)
    })
  end

  def coverables, do: @body_part_coverables
end
