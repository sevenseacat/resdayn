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
  Convert a UTF-8 string to Windows-1252 bytes for an ESP file.

  Delegates to `Resdayn.Windows1252.encode/1`, which drops any character with no
  Windows-1252 representation.

  ## Examples

      iex> encode_string("“Hello”")
      <<147, 72, 101, 108, 108, 111, 148>>

      iex> encode_string("café")
      <<99, 97, 102, 233>>

      iex> encode_string(nil)
      ""
  """
  def encode_string(nil), do: ""
  def encode_string(string) when is_binary(string), do: Resdayn.Windows1252.encode(string)

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
