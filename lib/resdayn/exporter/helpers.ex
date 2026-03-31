defmodule Resdayn.Exporter.Helpers do
  @moduledoc """
  Encoding primitives for the exporter — inverses of `Resdayn.Parser.Helpers`.
  """

  @doc """
  Null-pad a string to exactly `size` bytes.

  Inverse of `Resdayn.Parser.Helpers.truncate/1` for fixed-width fields.

  ## Examples

      iex> pad_string("Hello", 8)
      <<72, 101, 108, 108, 111, 0, 0, 0>>

      iex> pad_string(nil, 4)
      <<0, 0, 0, 0>>

      iex> pad_string("AB", 2)
      <<65, 66>>

      iex> pad_string(Ash.CiString.new("Hello"), 8)
      <<72, 101, 108, 108, 111, 0, 0, 0>>
  """
  def pad_string(nil, size), do: :binary.copy(<<0>>, size)

  def pad_string(string, size) when is_binary(string) and byte_size(string) >= size do
    binary_part(string, 0, size)
  end

  def pad_string(string, size) when is_binary(string) do
    string <> :binary.copy(<<0>>, size - byte_size(string))
  end

  def pad_string(string, size), do: pad_string(to_string(string), size)

  @doc """
  Null-terminate a string.

  Inverse of `Resdayn.Parser.Helpers.truncate/1` for variable-length fields.

  ## Examples

      iex> null_terminate("Morrowind.esm")
      "Morrowind.esm" <> <<0>>

      iex> null_terminate(nil)
      <<0>>

      iex> null_terminate(Ash.CiString.new("test"))
      "test" <> <<0>>
  """
  def null_terminate(nil), do: <<0>>
  def null_terminate(string) when is_binary(string), do: string <> <<0>>
  def null_terminate(string), do: null_terminate(to_string(string))

  @doc """
  Convert a UTF-8 string back to Windows-1252 encoding for ESP files.

  Inverse of `Resdayn.Parser.Helpers.clean_string_fast/1`.

  ## Examples

      iex> encode_string("\u201CHello\u201D")
      <<147, 72, 101, 108, 108, 111, 148>>

      iex> encode_string("caf\u00E9")
      <<99, 97, 102, 233>>

      iex> encode_string(nil)
      ""
  """
  def encode_string(nil), do: ""

  def encode_string(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&encode_char/1)
    |> :binary.list_to_bin()
  end

  # Unicode → Windows-1252 reverse mappings
  # Ellipsis (the parser expands byte 133 to three ASCII dots, so we can't
  # reliably reverse "..." back to a single byte — leave dots as-is)
  # ' → left single quote
  defp encode_char(0x2018), do: 145
  # ' → right single quote
  defp encode_char(0x2019), do: 146
  # " → left double quote
  defp encode_char(0x201C), do: 147
  # " → right double quote
  defp encode_char(0x201D), do: 148
  # — → em dash
  defp encode_char(0x2014), do: 151
  # Latin-1 Supplement characters (U+00A0–U+00FF) map directly to the same
  # byte values in Windows-1252
  defp encode_char(cp) when cp in 0x00A0..0x00FF, do: cp
  # ASCII range passes through unchanged
  defp encode_char(cp) when cp in 0..127, do: cp
  # Anything else we can't represent — drop it
  defp encode_char(_), do: ??

  @doc """
  Reconstruct an integer bitmask from a map of flags.

  Inverse of `Resdayn.Parser.Helpers.bitmask/2`.

  ## Examples

      iex> encode_bitmask(%{blocked: true, persistent: false}, blocked: 0x2000, persistent: 0x400)
      0x2000

      iex> encode_bitmask(%{blocked: true, persistent: true}, blocked: 0x2000, persistent: 0x400)
      0x2400

      iex> encode_bitmask(%{blocked: false, persistent: false}, blocked: 0x2000, persistent: 0x400)
      0
  """
  def encode_bitmask(flags_map, definitions) do
    Enum.reduce(definitions, 0, fn {key, value}, acc ->
      if Map.get(flags_map, key, false), do: Bitwise.bor(acc, value), else: acc
    end)
  end
end
