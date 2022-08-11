defmodule Resdayn.Formatter.Helpers do
  def fix_newlines(value) do
    String.replace(value, "\r\n", "\n")
  end
end
