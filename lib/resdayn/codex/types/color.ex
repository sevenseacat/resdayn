defmodule Resdayn.Codex.Types.Color do
  @moduledoc """
  Stores a hexadecimal string representing a RGB color.
  """

  use Ash.Type.NewType, subtype_of: :string, constraints: [match: ~r/^#[1234567890ABCDEF]{6}$/]
end
