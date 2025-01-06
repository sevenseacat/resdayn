defmodule Resdayn.Parser.Record.StartScript do
  use Resdayn.Parser.Record

  process_basic_string "NAME", :script_id

  def process({"DATA", _value}, data), do: data
end
