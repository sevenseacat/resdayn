defmodule Resdayn.Parser.Record.CreatureLevelledList do
  use Resdayn.Parser.Record

  process_basic_string "NAME", :id

  def process({"DATA", <<flags::uint32()>>}, data) do
    record_value(data, :flags, bitmask(flags, from_all_lower_levels: 0x1))
  end

  def process({"NNAM", <<value::uint8()>>}, data) do
    record_value(data, :chance_none, value)
  end

  def process({"INDX", <<value::uint32()>>}, data) do
    record_value(data, :creature_count, value)
  end

  def process({"CNAM" = v, value}, data) do
    record_list_of_maps_key(data, :creatures, :id, printable!(__MODULE__, v, value))
  end

  def process({"INTV", <<pc_level::uint16()>>}, data) do
    record_list_of_maps_value(data, :creatures, :player_level, pc_level)
  end
end
