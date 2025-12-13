defmodule Resdayn.Codex.Dialogue.Topic.Type do
  use Ash.Type.Enum,
    values: [
      topic: [label: "Topic"],
      voice: [label: "Voice"],
      greeting: [label: "Greeting"],
      persuasion: [label: "Persuasion"]
    ]
end
