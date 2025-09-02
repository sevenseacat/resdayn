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
    float
    |> :erlang.float_to_binary(decimals: 2)
    |> :erlang.binary_to_float()
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
    string = clean_string_fast(string)

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
                "#{inspect(source)}(#{field}): Unprintable value at #{name}[#{i}]: #{inspect(String.at(string, i - 1))}"
        end
      end
    end
  end

  # Optimized string cleaning - single pass instead of multiple String.replace calls
  defp clean_string_fast(string) do
    string
    |> truncate()
    |> String.replace("\r\n", "\n")
    |> String.replace(<<194, 151>>, "—")  # Handle 2-byte sequence first
    |> :binary.bin_to_list()
    |> Enum.flat_map(&replace_char/1)
    |> List.to_string()
    |> String.trim()
  end

  # Character replacements - using pattern matching for efficiency
  defp replace_char(1), do: []          # Remove null bytes
  defp replace_char(33), do: [?!]       # Replace with exclamation mark
  defp replace_char(133), do: ~c"..."   # Replace with ellipsis
  defp replace_char(146), do: [?']      # Replace with single quote
  defp replace_char(147), do: ~c"\""    # Windows-specific smart quote - replace with Unicode quote
  defp replace_char(148), do: ~c"\""    # Windows-specific smart quote - replace with Unicode quote
  defp replace_char(151), do: ~c"—"     # Em dash
  defp replace_char(173), do: []        # Remove soft hyphen
  defp replace_char(160), do: []        # Remove non-breaking space
  defp replace_char(225), do: ~c"á"     # á
  defp replace_char(232), do: ~c"è"     # è
  defp replace_char(233), do: ~c"é"     # é
  defp replace_char(239), do: ~c"ï"     # ï
  defp replace_char(246), do: ~c"ö"     # ö
  defp replace_char(250), do: ~c"ú"     # ú
  defp replace_char(251), do: ~c"û"     # û
  defp replace_char(char), do: [char]   # Keep all other characters as-is

  def null_separated!(source, field, string) do
    string
    |> truncate()
    |> String.split(<<0>>)
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
  def coordinates(value) do
    # One buggy reference in Tamriel Rebuilt - in the cell "Firewatch, Sewers: Uriel's Quarter"
    # has a malformed `rot_x` value for some reason
    radians_to_degrees = fn num -> num * 180 / :math.pi() end

    <<pos_x::float32(), pos_y::float32(), pos_z::float32(), rot_x::binary-size(4),
      rot_y::float32(), rot_z::float32()>> = value

    rot_x =
      case rot_x do
        <<rot_x::float32()>> -> float(normalize_angle(radians_to_degrees.(rot_x)))
        _ -> nil
      end

    %{
      position: %{x: float(pos_x), y: float(pos_y), z: float(pos_z)},
      rotation: %{
        x: rot_x,
        y: float(normalize_angle(radians_to_degrees.(rot_y))),
        z: float(normalize_angle(radians_to_degrees.(rot_z)))
      }
    }
  end
end
