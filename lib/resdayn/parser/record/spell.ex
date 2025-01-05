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

  @spell_range_mapping %{
    0 => :self,
    1 => :touch,
    2 => :target
  }

  process_basic_string "NAME", :id
  process_basic_string "FNAM", :name

  def process({"SPDT", value}, data) do
    <<type::uint32(), cost::uint32(), flags::uint32()>> = value

    record_unnested_value(data, %{
      type: Map.fetch!(@spell_type_mapping, type),
      cost: cost,
      flags: bitmask(flags, autocalc: 1, starting_spell: 2, always_succeeds: 4)
    })
  end

  def process({"ENAM", value}, data) do
    <<effect::uint16(), skill::int8(), attribute::int8(), range::uint32(), area::uint32(),
      duration::uint32(), min::uint32(), max::uint32()>> = value

    record_list(data, :enchantments, %{
      magic_effect_id: effect,
      skill_id: nil_if_negative(skill),
      attribute_id: nil_if_negative(attribute),
      range: Map.fetch!(@spell_range_mapping, range),
      area: area,
      duration: duration,
      magnitude: %{min: min, max: max}
    })
  end
end
