defmodule Resdayn.Codex.Dialogue.Topic.Type do
  use Ash.Type.Enum,
    values: [topic: "Topic", voice: "Voice", greeting: "Greeting", persuasion: "Persuasion"]
end
