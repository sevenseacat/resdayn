defmodule Resdayn.Parser.Helpers do
  @doc """
  Remove all null-bytes from the end of a padded string.

  iex> Helpers.truncate(<<66, 101, 116, 104, 101, 115, 100, 97, 32, 83, 111, 102, 116,
  119, 111, 114, 107, 115, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>)
  "Bethesda Softworks"
  """
  def truncate(string), do: String.trim_trailing(string, <<0>>)

  @doc """
  iex> Helpers.bitmask(0x02, blocked: 0x01, persistent: 0x02)
  %{blocked: false, persistent: true}
  """
  def bitmask(mask, list) do
    Enum.reduce(list, %{}, fn {key, value}, acc ->
      Map.put(acc, key, Bitwise.band(mask, value) == value)
    end)
  end
end
