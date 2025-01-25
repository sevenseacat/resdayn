defmodule Resdayn.Parser.Record.Script do
  use Resdayn.Parser.Record

  process_basic_string "SCTX", :text

  def process({"SCHD" = v, value}, data) do
    <<id::char(32), num_shorts::uint32(), num_longs::uint32(), num_floats::uint32(),
      data_size::uint32(), local_variable_size::uint32()>> = value

    record_unnested_value(data, %{
      id: printable!(__MODULE__, v, id),
      num_shorts: num_shorts,
      num_longs: num_longs,
      num_floats: num_floats,
      data_size: data_size,
      local_variable_size: local_variable_size
    })
  end

  # We really don't care about compiled script data
  def process({"SCDT", _value}, data), do: data

  def process({"SCVR" = v, value}, data) do
    record_value(data, :local_variables, null_separated!(__MODULE__, v, value))
  end
end
