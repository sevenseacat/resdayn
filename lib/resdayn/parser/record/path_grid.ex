defmodule Resdayn.Parser.Record.PathGrid do
  # This is the least interesting record type - ignore it.
  use Resdayn.Parser.Record

  process_basic_string "NAME", :cell_name

  def process({_, _}, data), do: data
end
