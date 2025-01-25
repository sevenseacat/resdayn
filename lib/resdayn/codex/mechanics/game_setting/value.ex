defmodule Resdayn.Codex.Mechanics.GameSetting.Value do
  use Ash.Type.NewType,
    subtype_of: :union,
    constraints: [
      types: [
        string: [type: :string],
        integer: [type: :integer],
        float: [type: :float]
      ]
    ]
end
