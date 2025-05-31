defmodule Resdayn.Codex.Dialogue.Response.Operator do
  use Ash.Type.Enum, values: [:=, :!=, :>, :>=, :<, :<=]
end
