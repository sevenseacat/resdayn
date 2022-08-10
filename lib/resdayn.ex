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
    Resdayn.Parser.File.read(filename)
  end
end
