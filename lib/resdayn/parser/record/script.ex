defmodule Resdayn.Parser.Record.Script do
  use Resdayn.Parser.Record

  def process({"SCHD" = v, value}, data) do
    <<name::char(32), num_shorts::long(), num_longs::long(), num_floats::long(),
      data_size::long(), local_variable_size::long()>> = value

    record_unnested_value(data, %{
      name: printable!(__MODULE__, v, name),
      num_shorts: num_shorts,
      num_longs: num_longs,
      num_floats: num_floats,
      data_size: data_size,
      local_variable_size: local_variable_size
    })
  end

  # We really don't care about compiled script data
  def process({"SCDT", _value}, data), do: data

  def process({"SCTX" = v, value}, data) do
    record_value(data, :text, printable!(__MODULE__, v, value))
  end

  def process({"SCVR" = v, value}, data) do
    record_value(data, :local_variables, null_separated!(__MODULE__, v, value))
  end
end
