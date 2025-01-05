defmodule Resdayn.Parser.Record.Enchantment do
  use Resdayn.Parser.Record

  @enchantment_types %{
    0 => :cast_once,
    1 => :cast_on_strike,
    2 => :cast_when_used,
    3 => :constant_effect
  }

  process_basic_string "NAME", :id
  process_enchantments "ENAM", :enchantments

  def process({"ENDT", value}, data) do
    <<type::uint32(), cost::uint32(), charge::uint32(), flags::uint32()>> = value

    record_unnested_value(data, %{
      type: Map.fetch!(@enchantment_types, type),
      cost: cost,
      charge: charge,
      flags: bitmask(flags, autocalc: 0x1)
    })
  end
end
