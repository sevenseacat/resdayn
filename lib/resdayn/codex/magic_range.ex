defmodule Resdayn.Codex.MagicRange do
  use Ash.Type.Enum, values: [self: "On Self", touch: "On Touch", target: "On Target"]
end
