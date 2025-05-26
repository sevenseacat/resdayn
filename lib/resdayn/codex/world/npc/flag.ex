defmodule Resdayn.Codex.World.NPC.Flag do
  use Ash.Type.Enum, values: [:female, :respawn, :essential, :autocalc]
end
