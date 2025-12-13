defmodule Resdayn.Codex.Assets.LightFlag do
  use Ash.Type.Enum,
    values: [
      dynamic: [label: "Dynamic"],
      can_carry: [label: "Can be carried"],
      negative: [label: "Negative"],
      flicker: [label: "Flicker"],
      fire: [label: "Fire"],
      off_by_default: [label: "Off by default"],
      flicker_slow: [label: "Slow flicker"],
      pulse: [label: "Pulse"],
      pulse_slow: [label: "Slow pulse"]
    ]
end
