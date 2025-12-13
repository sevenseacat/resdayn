defmodule Resdayn.Codex.World.Cell.Flag do
  use Ash.Type.Enum,
    values: [
      interior: [label: "Interior"],
      has_water: [label: "Has water"],
      sleeping_illegal: [label: "Sleeping is illegal"],
      behave_like_exterior: [label: "Behaves like an exterior"]
    ]
end
