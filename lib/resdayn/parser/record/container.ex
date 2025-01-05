defmodule Resdayn.Parser.Record.Container do
  use Resdayn.Parser.Record

  process_basic_string "NAME", :id
  process_basic_string "MODL", :nif_model
  process_basic_string "FNAM", :name

  def process({"CNDT", <<value::float32()>>}, data) do
    record_value(data, :capacity, value)
  end

  def process({"FLAG", <<value::uint32()>>}, data) do
    record_value(data, :flags, bitmask(value, organic: 0x1, respawns: 0x2))
  end
end
