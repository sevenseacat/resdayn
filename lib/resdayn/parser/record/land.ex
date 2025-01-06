defmodule Resdayn.Parser.Record.Land do
  # This is the least interesting record type - ignore it.
  use Resdayn.Parser.Record

  def process({"INTV", value}, data) do
    <<x::int32(), y::int32()>> = value
    record_value(data, :position, {x, y})
  end

  def process({_, _}, data), do: data
end
