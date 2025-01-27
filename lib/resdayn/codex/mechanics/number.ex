defmodule Resdayn.Codex.Mechanics.Number do
  use Ash.Type.NewType,
    subtype_of: :union,
    constraints: [
      types: [
        integer: [type: :integer],
        float: [type: :float]
      ]
    ]
end
