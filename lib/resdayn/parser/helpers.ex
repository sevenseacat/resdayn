defmodule Resdayn.Parser.Helpers do
  import Resdayn.Parser.DataSizes

  @doc """
  iex> Resdayn.Parser.Helpers.bitmask(0x02, blocked: 0x01, persistent: 0x02)
  %{blocked: false, persistent: true}
  """
  def bitmask(mask, list) do
    Enum.reduce(list, %{}, fn {key, value}, acc ->
      Map.put(acc, key, Bitwise.band(mask, value) == value)
    end)
  end

  @doc """
  Remove everything after a null-byte in a padded string.

  iex> Resdayn.Parser.Helpers.truncate(<<66, 101, 116, 104, 101, 115, 100, 97,
  ...> 32, 83, 111, 102, 116, 119, 111, 114, 107, 115, 0, 0, 0, 0, 0, 0, 0, 0,
  ...> 0, 0, 0, 0, 0, 0>>)
  "Bethesda Softworks"

  iex> Resdayn.Parser.Helpers.truncate(<<112, 114, 111, 112, 121, 108, 111, 110,
  ...> 32, 99, 104, 97, 109, 98, 101, 114, 46, 0, 114, 111, 112, 121, 108, 111, 110, 32>>)
  "propylon chamber."
  """
  def truncate(string) do
    hd(String.split(string, <<0>>))
  end

  @doc """
  Round a floating-point number to a reasonable number of decimal places.
  """
  def float(float) do
    Float.round(float, 2)
  end

  @doc """
  Convert a four-byte float into a two-byte short value.
  Only used in one place - when parsing global variable values.
  See HelpersTest for tests for all of the values used in `Morrowind.esm`
  """
  def float_to_short(value) do
    if match?(<<_::lfloat()>>, value) do
      <<parsed::lfloat()>> = value

      # Junk values get discarded
      if parsed < -32768 || parsed > 32767 do
        0
      else
        round(parsed)
      end
    else
      0
    end
  end

  @doc """
  Ensure that a given string is entirely printable,
  ie. it contains no special characters or no null-byte characters

  If it is not printable, raises an error with info about where it was sourced from
  for debugging purposes
  """
  def printable!(source, field, name \\ "data", string) do
    string = truncate(string)

    if String.printable?(string) do
      string
    else
      # Debugging to see where the unprintable value is
      for i <- 0..String.length(string) do
        if !String.printable?(string, i) do
          raise RuntimeError,
                "#{inspect(source)}(#{field}): Unprintable value at #{name}[#{i}]: #{inspect(String.at(string, i - 1))}"
        end
      end
    end
  end

  @doc """
  Convert an encoded RGB colour value into a hexadecimal value suitable for using in HTML.
  """
  def color(<<red::integer-8, green::integer-8, blue::integer-8, _rest>>) do
    color({red, green, blue})
  end

  def color({red, green, blue}) do
    "#" <> Base.encode16(<<red, green, blue>>)
  end
end
