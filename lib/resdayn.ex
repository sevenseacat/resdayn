defmodule Resdayn do
  @moduledoc """
  `Resdayn` is an Elixir application for reading, parsing and formatting data
  from ESM data files from The Elder Scrolls III: Morrowind.
  """

  @doc """
  Load the specified ESM file.

  iex> Resdayn.load("Morrowind.esm")
  [records]
  """
  def load(filename) do
    filename
    |> stream()
    |> Enum.to_list()
  end

  @doc """
  Stream records from the specified ESM file.

  iex> Resdayn.stream("Morrowind.esm") |> Enum.take(1)
  %{type: :master, ...}
  """
  def stream(filename) do
    filename
    |> Resdayn.Parser.stream()
    |> Resdayn.Formatter.format()
  end
end
