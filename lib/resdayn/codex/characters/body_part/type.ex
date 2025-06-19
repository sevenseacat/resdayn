defmodule Resdayn.Codex.Characters.BodyPart.Type do
  use Ash.Type.Enum,
    values: [
      :head,
      :hair,
      :neck,
      :chest,
      :groin,
      :hand,
      :wrist,
      :forearm,
      :upper_arm,
      :foot,
      :ankle,
      :knee,
      :upper_leg,
      :clavicle,
      :tail
    ]
end
