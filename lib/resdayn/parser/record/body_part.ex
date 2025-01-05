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

  @equipment_types %{
    0 => :skin,
    1 => :clothing,
    2 => :armour
  }

  process_basic_string "NAME", :id
  process_basic_string "MODL", :nif_model
  process_basic_string "FNAM", :race

  def process({"BYDT", value}, data) do
    <<type::uint8(), vampire::uint8(), flags::uint8(), equipment_type::uint8()>> = value

    record_unnested_value(data, %{
      type: Map.fetch!(@body_part_types, type),
      vampire: vampire == 1,
      flags: bitmask(flags, female: 0x1, playable: 0x2),
      equipment_type: Map.fetch!(@equipment_types, equipment_type)
    })
  end
end
