defmodule Resdayn.Parser.Record.LandTexture do
  use Resdayn.Parser.Record

  def process({"NAME" = v, value}, data) do
    record_value(data, :id, printable!(__MODULE__, v, value))
  end

  def process({"INTV", <<value::long()>>}, data) do
    record_value(data, :index, value)
  end

  def process({"DATA" = v, value}, data) do
    record_value(data, :texture, printable!(__MODULE__, v, value))
  end
end
