defmodule Resdayn.Codex.MagicRange do
  use Ash.Type.Enum,
    values: [
      self: [label: "On Self"],
      touch: [label: "On Touch"],
      target: [label: "On Target"]
    ]
end
