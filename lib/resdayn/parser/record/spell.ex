defmodule Resdayn.Parser.Record.Spell do
  use Resdayn.Parser.Record

  @spell_type_mapping %{
    0 => :spell,
    1 => :ability,
    2 => :blight,
    3 => :disease,
    4 => :curse,
    5 => :power
  }

  process_basic_string "NAME", :id
  process_basic_string "FNAM", :name
  process_enchantments "ENAM", :enchantments

  def process({"SPDT", value}, data) do
    <<type::uint32(), cost::uint32(), flags::uint32()>> = value

    record_unnested_value(data, %{
      type: Map.fetch!(@spell_type_mapping, type),
      cost: cost,
      flags: bitmask(flags, autocalc: 1, starting_spell: 2, always_succeeds: 4)
    })
  end
end
