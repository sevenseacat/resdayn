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

  # Decode a raw ESP/ESM string to UTF-8: convert from Windows-1252, truncate at the
  # null padding, normalize line endings, and strip control-character corruption.
  defp sanitize_string(string) do
    string
    |> decode_win1252(<<>>)
    |> String.trim()
  end

  # 0x80–0x9F is the range where Windows-1252 puts printable symbols whose Unicode code
  # point is not the byte value, so they need an explicit mapping. `nil` marks the five
  # bytes that are undefined in the encoding; we drop them. (Matches `iconv -c`.)
  @win1252_overrides %{
    0x80 => 0x20AC,
    0x81 => nil,
    0x82 => 0x201A,
    0x83 => 0x0192,
    0x84 => 0x201E,
    0x85 => 0x2026,
    0x86 => 0x2020,
    0x87 => 0x2021,
    0x88 => 0x02C6,
    0x89 => 0x2030,
    0x8A => 0x0160,
    0x8B => 0x2039,
    0x8C => 0x0152,
    0x8D => nil,
    0x8E => 0x017D,
    0x8F => nil,
    0x90 => nil,
    0x91 => 0x2018,
    0x92 => 0x2019,
    0x93 => 0x201C,
    0x94 => 0x201D,
    0x95 => 0x2022,
    0x96 => 0x2013,
    0x97 => 0x2014,
    0x98 => 0x02DC,
    0x99 => 0x2122,
    0x9A => 0x0161,
    0x9B => 0x203A,
    0x9C => 0x0153,
    0x9D => nil,
    0x9E => 0x017E,
    0x9F => 0x0178
  }

  # Byte→code-point table for the high range (128–255): 0xA0–0xFF map to themselves
  # (code point == byte value), 0x80–0x9F come from @win1252_overrides above.
  @win1252 Map.new(128..255, fn byte -> {byte, Map.get(@win1252_overrides, byte, byte)} end)

  # CRLF → LF
  defp decode_win1252(<<"\r\n", rest::binary>>, acc),
    do: decode_win1252(rest, <<acc::binary, ?\n>>)

  # Null byte ends the string — fields are null-padded to a fixed width, so everything
  # past the first null is padding, not content.
  defp decode_win1252(<<0, _::binary>>, acc), do: acc
  defp decode_win1252(<<>>, acc), do: acc

  # Control characters (except tab/newline) are corruption, not text — e.g. a stray SOH
  # trailing a script-reference ID. Strip them.
  defp decode_win1252(<<byte, rest::binary>>, acc)
       when (byte < 0x20 or byte == 0x7F) and byte not in [?\t, ?\n],
       do: decode_win1252(rest, acc)

  # Normalize invisible spacing chars to their visible ASCII equivalents: NBSP → space,
  # soft hyphen → hyphen. Both are used as ordinary space/hyphen in book prose.
  defp decode_win1252(<<0xA0, rest::binary>>, acc), do: decode_win1252(rest, <<acc::binary, ?\s>>)
  defp decode_win1252(<<0xAD, rest::binary>>, acc), do: decode_win1252(rest, <<acc::binary, ?->>)

  # High range (128–255) — convert via the Windows-1252 table, dropping undefined bytes
  defp decode_win1252(<<byte, rest::binary>>, acc) when byte >= 128 do
    case Map.fetch!(@win1252, byte) do
      nil -> decode_win1252(rest, acc)
      code_point -> decode_win1252(rest, <<acc::binary, code_point::utf8>>)
    end
  end

  # Printable ASCII (plus the tab/newline kept above) — passes through unchanged
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
