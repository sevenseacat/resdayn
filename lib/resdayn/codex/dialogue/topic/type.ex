defmodule Resdayn.Codex.Dialogue.Topic.Type do
  use Ash.Type.Enum, values: [:topic, :voice, :greeting, :persuasion]
end
