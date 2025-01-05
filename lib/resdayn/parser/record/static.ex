defmodule Resdayn.Parser.Record.Static do
  use Resdayn.Parser.Record

  def process({"NAME" = v, value}, data) do
    record_value(data, :id, printable!(__MODULE__, v, value))
  end

  def process({"MODL" = v, value}, data) do
    record_value(data, :nif_model, printable!(__MODULE__, v, value))
  end
end
