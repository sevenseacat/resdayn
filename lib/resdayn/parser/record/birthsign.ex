defmodule Resdayn.Parser.Record.Birthsign do
  use Resdayn.Parser.Record

  def process({"NAME" = v, value}, data) do
    record_value(data, :id, printable!(__MODULE__, v, value))
  end

  def process({"FNAM" = v, value}, data) do
    record_value(data, :name, printable!(__MODULE__, v, value))
  end

  def process({"TNAM" = v, value}, data) do
    record_value(data, :artwork, printable!(__MODULE__, v, value))
  end

  def process({"DESC" = v, value}, data) do
    record_value(data, :description, printable!(__MODULE__, v, value))
  end

  def process({"NPCS" = v, value}, data) do
    record_list(data, :special_ids, printable!(__MODULE__, v, value))
  end
end
