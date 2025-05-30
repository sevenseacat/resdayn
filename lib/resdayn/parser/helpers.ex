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
    # 147 and 148 are Windows-specific smart quotes - replace with Unicode quotes
    # 173 is a "soft hyphen" - just delete them
    # 239 is a ï as in naïve - it works if you tell Elixir it's encoded in UTF8 but not otherwise
    # 250 is a ú - same deal
    # 133 is a ...
    # 232 is è
    # 233 is é
    # 160 is a non-breaking space!?
    # 225 is a á
    # 251 is a û
    string =
      string
      |> truncate()
      |> String.replace(<<1>>, "")
      |> String.replace(<<33>>, "!")
      |> String.replace(<<133>>, <<"...">>)
      |> String.replace(<<146>>, "’")
      |> String.replace(<<147>>, "“")
      |> String.replace(<<148>>, "”")
      |> String.replace(<<151>>, <<151::utf8>>)
      |> String.replace(<<173>>, "")
      |> String.replace(<<194, 151>>, <<"—">>)
      |> String.replace(<<225>>, <<225::utf8>>)
      |> String.replace(<<232>>, <<232::utf8>>)
      |> String.replace(<<233>>, <<233::utf8>>)
      |> String.replace(<<239>>, <<239::utf8>>)
      |> String.replace(<<246>>, <<246::utf8>>)
      |> String.replace(<<250>>, <<250::utf8>>)
      |> String.replace(<<251>>, <<251::utf8>>)
      |> String.replace("\r\n", "\n")
      |> String.replace(<<160>>, "")
      |> String.trim()

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
