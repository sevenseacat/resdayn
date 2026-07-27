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
    if match?(<<_::float32()>>, value) do
      <<parsed::float32()>> = value

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
    string = Resdayn.Windows1252.decode(string)

    if String.printable?(string) do
      if string == "" do
        nil
      else
        string
      end
    else
      # Debugging to see where the unprintable value is
      for i <- 0..String.length(string) do
        if !String.printable?(string, i) do
          raise RuntimeError,
                "#{inspect(source)}(#{field}): Unprintable value at #{name}[#{i}]: #{inspect(String.at(string, i - 1))}. Seen so far: #{String.slice(string, 0, i - 1)}"
        end
      end
    end
  end

  def null_separated!(source, field, string) do
    string
    |> String.split(<<0>>, trim: true)
    |> Enum.map(&printable!(source, field, &1))
  end

  @doc """
  Convert an encoded RGB colour value into a hexadecimal value suitable for using in HTML.
  """
  def color(<<red::int8(), green::int8(), blue::int8(), 0::int8()>>) do
    color({red, green, blue})
  end

  def color({red, green, blue}) do
    "#" <> Base.encode16(<<red, green, blue>>)
  end

  @doc """
  Unset "N/A" negative values of subrecords.
  This is used for fields like "which skill ID does this spell affect, -1 if none"
  """
  def nil_if_negative(value) when value < 0, do: nil
  def nil_if_negative(value), do: value

  # Normalize angle to -180 to 180 range
  defp normalize_angle(angle) do
    # Use modulo for floats and integers
    normalized = angle - 360 * floor(angle / 360)
    if normalized > 180, do: normalized - 360, else: normalized
  end

  @doc """
  Parse a set of position/rotation coordinates.
  Used for positioning of items and travel destinations
  """
  def coordinates(
        <<pos_x::float32(), pos_y::float32(), pos_z::float32(), rot_x::float32(),
          rot_y::float32(), rot_z::float32()>>
      ) do
    radians_to_degrees = fn num -> float(normalize_angle(num * 180 / :math.pi())) end

    %{
      position: %{x: float(pos_x), y: float(pos_y), z: float(pos_z)},
      rotation: %{
        x: radians_to_degrees.(rot_x),
        y: radians_to_degrees.(rot_y),
        z: radians_to_degrees.(rot_z)
      }
    }
  end
end
