defmodule Resdayn.Parser.Record.SoundGenerator do
  use Resdayn.Parser.Record

  @sound_types %{
    0 => :left_foot,
    1 => :right_foot,
    2 => :swim_left,
    3 => :swim_right,
    4 => :moan,
    5 => :roar,
    6 => :scream,
    7 => :land
  }
  process_basic_string "NAME", :id
  process_basic_string "SNAM", :sound_id
  process_basic_string "CNAM", :creature_key

  def process({"DATA", <<value::uint32()>>}, data) do
    record_value(data, :sound_type, Map.fetch!(@sound_types, value))
  end
end
