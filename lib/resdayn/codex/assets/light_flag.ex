defmodule Resdayn.Codex.Assets.LightFlag do
  use Ash.Type.Enum,
    values: [
      dynamic: "Dynamic",
      can_carry: "Can be carried",
      negative: "Negative",
      flicker: "Flicker",
      fire: "Fire",
      off_by_default: "Off by default",
      flicker_slow: "Slow flicker",
      pulse: "Pulse",
      pulse_slow: "Slow pulse"
    ]
end
