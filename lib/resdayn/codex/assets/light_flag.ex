defmodule Resdayn.Codex.Assets.LightFlag do
  use Ash.Type.Enum, values: [
    :dynamic,
    :can_carry,
    :negative,
    :flicker,
    :fire,
    :off_by_default,
    :flicker_slow,
    :pulse,
    :pulse_slow
  ]
end