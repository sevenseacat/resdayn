defmodule Resdayn.Parser.DataSizes do
  @moduledoc """
  Defines common data sizes to be used in pattern matching ESM file contents.

  The type names reflect the names used in the master mw_esm.txt file, where possible.

  ## Differences

  * float -> lfloat (conflicts with default Elixir float type)

  ## Examples

  iex> <<value::long()>> = File.read(file, 32)
  """
  defmacro char(size) do
    quote do
      binary - size(unquote(size))
    end
  end

  defmacro int do
    quote do
      little - integer - signed - size(32)
    end
  end

  defmacro lfloat do
    quote do
      little - float - signed - size(32)
    end
  end

  defmacro long do
    quote do
      little - integer - size(32)
    end
  end

  defmacro long64 do
    quote do
      little - integer - size(64)
    end
  end
end
