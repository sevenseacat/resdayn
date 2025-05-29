defmodule Resdayn.Codex.Assets.SoundGenerator.SoundType do
  use Ash.Type.Enum,
    values: [
      :left_foot,
      :right_foot,
      :swim_left,
      :swim_right,
      :moan,
      :roar,
      :scream,
      :land
    ]
end