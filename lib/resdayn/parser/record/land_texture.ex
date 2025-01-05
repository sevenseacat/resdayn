defmodule Resdayn.Parser.Record.LandTexture do
  use Resdayn.Parser.Record

  process_basic_string "NAME", :id
  process_basic_string "DATA", :texture

  def process({"INTV", <<value::uint32()>>}, data) do
    record_value(data, :index, value)
  end
end
