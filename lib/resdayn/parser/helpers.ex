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
    string = sanitize_string(string)

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

  # Sanitize a raw ESP/ESM string: truncate at null bytes, normalize line endings,
  # strip junk bytes, and convert from Windows-1252 encoding to UTF-8.
  defp sanitize_string(string) do
    string
    |> decode_win1252(<<>>)
    |> String.trim()
  end

  # Null byte — end of string (replaces truncate/1)
  defp decode_win1252(<<0, _::binary>>, acc), do: acc
  defp decode_win1252(<<>>, acc), do: acc

  # CRLF → LF (replaces String.replace/3)
  defp decode_win1252(<<"\r\n", rest::binary>>, acc),
    do: decode_win1252(rest, <<acc::binary, ?\n>>)

  # Junk bytes — remove
  defp decode_win1252(<<1, rest::binary>>, acc), do: decode_win1252(rest, acc)
  defp decode_win1252(<<160, rest::binary>>, acc), do: decode_win1252(rest, acc)
  defp decode_win1252(<<173, rest::binary>>, acc), do: decode_win1252(rest, acc)

  # Control char → space
  defp decode_win1252(<<31, rest::binary>>, acc),
    do: decode_win1252(rest, <<acc::binary, ?\s>>)

  # Windows-1252 specific (bytes 128-159 that diverge from Latin-1)
  defp decode_win1252(<<133, rest::binary>>, acc),
    do: decode_win1252(rest, <<acc::binary, "...">>)

  defp decode_win1252(<<145, rest::binary>>, acc),
    do: decode_win1252(rest, <<acc::binary, 0x2018::utf8>>)

  defp decode_win1252(<<146, rest::binary>>, acc),
    do: decode_win1252(rest, <<acc::binary, 0x2019::utf8>>)

  defp decode_win1252(<<147, rest::binary>>, acc),
    do: decode_win1252(rest, <<acc::binary, 0x201C::utf8>>)

  defp decode_win1252(<<148, rest::binary>>, acc),
    do: decode_win1252(rest, <<acc::binary, 0x201D::utf8>>)

  defp decode_win1252(<<151, rest::binary>>, acc),
    do: decode_win1252(rest, <<acc::binary, 0x2014::utf8>>)

  # Non-ASCII Latin-1 range (bytes 160-255) — code point equals byte value,
  # just needs UTF-8 multi-byte encoding
  defp decode_win1252(<<byte, rest::binary>>, acc) when byte > 127,
    do: decode_win1252(rest, <<acc::binary, byte::utf8>>)

  # ASCII (bytes 1-127) — passes through unchanged
  defp decode_win1252(<<byte, rest::binary>>, acc),
    do: decode_win1252(rest, <<acc::binary, byte>>)

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
