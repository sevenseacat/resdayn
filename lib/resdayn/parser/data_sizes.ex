defmodule Resdayn.Parser.DataSizes do
  @moduledoc """
  Defines common data sizes to be used in pattern matching ESM file contents.

  The type names reflect the names used in the UESP wiki, where possible.

  ## Examples

  iex> <<value::uint32()>> = File.read(file, 32)
  """
  defmacro char(size) do
    quote do
      binary - size(unquote(size))
    end
  end

  defmacro int8 do
    quote do
      little - integer - signed - size(8)
    end
  end

  defmacro uint8 do
    quote do
      little - integer - unsigned - size(8)
    end
  end

  defmacro uint16 do
    quote do
      little - integer - unsigned - size(16)
    end
  end

  defmacro float32 do
    quote do
      little - float - size(32)
    end
  end

  defmacro int32 do
    quote do
      little - integer - signed - size(32)
    end
  end

  defmacro uint32 do
    quote do
      little - integer - unsigned - size(32)
    end
  end

  defmacro uint64 do
    quote do
      little - integer - unsigned - size(64)
    end
  end
end
