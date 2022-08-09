defmodule Resdayn.DataSizes do
  @moduledoc """
  Defines common data sizes to be used in pattern matching ESM file contents.

  ## Examples

  iex> <<value::long>> = File.read(file, 32)
  """
  defmacro long do
    quote do: little - integer - 32
  end

  defmacro long64 do
    quote do: little - integer - 64
  end

  defmacro float do
    quote do: little - float - 32
  end

  defmacro short do
    quote do: little - integer - 16
  end

  defmacro byte do
    quote do: little - integer - 8
  end
end
