defmodule Resdayn.Catalog.Dialogue.Response.Operator do
  use Ash.Type.Enum, values: [:=, :!=, :>, :>=, :<, :<=]
end
