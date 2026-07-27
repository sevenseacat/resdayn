defmodule Resdayn.Windows1252 do
  @moduledoc """
  Converts the text in ESM/ESP files between raw Windows-1252 bytes and UTF-8.

  `decode/1` and `encode/1` are the whole public surface, and they are
  deliberately **not** exact inverses. `decode/1` does the messy job of turning
  decades-old game bytes into a clean string — in one pass it truncates at the
  null padding, maps Windows-1252 to Unicode, normalizes line endings, strips
  control-character corruption, and turns non-breaking spaces and soft hyphens
  into ordinary spaces and hyphens. `encode/1` is the plain reverse mapping,
  code point to byte. All the per-byte handling stays private.

  Both directions share one `@overrides` table, so the mapping can't drift.
  Characters with no representation in the target are dropped (matching
  `iconv -c`): the five undefined bytes in `0x80..0x9F` on decode, and any
  non-Windows-1252 code point on encode.
  """

  # 0x80..0x9F hold printable symbols whose code point is not the byte value.
  # The five `nil`s are the bytes Windows-1252 leaves undefined. 0xA0..0xFF map
  # to their own value (Latin-1 Supplement) and so aren't listed here.
  @overrides %{
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

  # Byte → code-point table for the high range (128–255).
  @decode Map.new(128..255, fn byte -> {byte, Map.get(@overrides, byte, byte)} end)

  # Code-point → byte, the inverse of @decode with the undefined bytes removed.
  @encode @decode
          |> Enum.reject(fn {_byte, code_point} -> is_nil(code_point) end)
          |> Map.new(fn {byte, code_point} -> {code_point, byte} end)

  @doc """
  Decode raw Windows-1252 bytes from an ESM/ESP file into a clean UTF-8 string.

  See the module doc for what "clean" strips and normalizes. Single pass over
  the input.
  """
  def decode(binary) when is_binary(binary) do
    binary
    |> do_decode(<<>>)
    |> String.trim()
  end

  # CRLF → LF
  defp do_decode(<<"\r\n", rest::binary>>, acc), do: do_decode(rest, <<acc::binary, ?\n>>)

  # A null byte ends the field — everything past it is fixed-width padding.
  defp do_decode(<<0, _::binary>>, acc), do: acc
  defp do_decode(<<>>, acc), do: acc

  # Control characters (except tab/newline) are corruption, not text — e.g. a
  # stray SOH trailing a script-reference id, or a lone CR. Strip them.
  defp do_decode(<<byte, rest::binary>>, acc)
       when (byte < 0x20 or byte == 0x7F) and byte not in [?\t, ?\n],
       do: do_decode(rest, acc)

  # Invisible spacing chars → their visible ASCII equivalents. Book prose uses
  # NBSP as an ordinary space and soft hyphen as an ordinary hyphen.
  defp do_decode(<<0xA0, rest::binary>>, acc), do: do_decode(rest, <<acc::binary, ?\s>>)
  defp do_decode(<<0xAD, rest::binary>>, acc), do: do_decode(rest, <<acc::binary, ?->>)

  # High range (128–255) — map via the table, dropping the undefined bytes.
  defp do_decode(<<byte, rest::binary>>, acc) when byte >= 128 do
    case Map.fetch!(@decode, byte) do
      nil -> do_decode(rest, acc)
      code_point -> do_decode(rest, <<acc::binary, code_point::utf8>>)
    end
  end

  # Printable ASCII (plus the tab/newline kept above) — passes through unchanged.
  defp do_decode(<<byte, rest::binary>>, acc), do: do_decode(rest, <<acc::binary, byte>>)

  @doc """
  Encode a UTF-8 string to Windows-1252 bytes, dropping any character with no
  Windows-1252 representation.
  """
  def encode(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.flat_map(&encode_char/1)
    |> :binary.list_to_bin()
  end

  defp encode_char(code_point) when code_point in 0..127, do: [code_point]

  defp encode_char(code_point) do
    case Map.get(@encode, code_point) do
      nil -> []
      byte -> [byte]
    end
  end
end
