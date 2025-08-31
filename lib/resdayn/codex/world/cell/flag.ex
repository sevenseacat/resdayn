defmodule Resdayn.Codex.World.Cell.Flag do
  use Ash.Type.Enum,
    values: [
      interior: "Interior",
      has_water: "Has water",
      sleeping_illegal: "Sleeping is illegal",
      behave_like_exterior: "Behaves like an exterior"
    ]
end
