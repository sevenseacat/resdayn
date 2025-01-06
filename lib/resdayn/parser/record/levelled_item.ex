defmodule Resdayn.Parser.Record.LevelledItem do
  use Resdayn.Parser.Record

  process_basic_string "NAME", :id

  def process({"DATA", <<flags::uint32()>>}, data) do
    record_value(data, :flags, bitmask(flags, for_each_item: 0x1, from_all_lower_levels: 0x2))
  end

  def process({"NNAM", <<value::uint8()>>}, data) do
    record_value(data, :chance_none, value)
  end

  def process({"INDX", <<value::uint32()>>}, data) do
    record_value(data, :item_count, value)
  end

  def process({"INAM" = v, value}, data) do
    record_list_of_maps_key(data, :items, :id, printable!(__MODULE__, v, value))
  end

  def process({"INTV", <<pc_level::uint16()>>}, data) do
    record_list_of_maps_value(data, :items, :pc_level, pc_level)
  end
end
