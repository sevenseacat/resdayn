defmodule Resdayn.QuestAnalyzer.Helpers do
  @moduledoc "Helper functions for the quest analyzer."

  def str(%Ash.CiString{} = value), do: String.downcase(to_string(value))
  def str(value) when is_binary(value), do: String.downcase(value)
end
