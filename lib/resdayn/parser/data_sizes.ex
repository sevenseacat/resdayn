defmodule Resdayn.Parser.DataSizes do
  @moduledoc """
  Defines common data sizes to be used in pattern matching ESM file contents.

  The type names reflect the names used in the master mw_esm.txt file.

  ## Examples

  iex> <<value::long()>> = File.read(file, 32)
  """
  defmacro char(size) do
    quote do
      binary - size(unquote(size))
    end
  end

  defmacro long do
    quote do
      little - integer - size(32)
    end
  end
end
