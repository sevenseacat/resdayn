defmodule Resdayn.Codex.Dialogue.Topic.RelatedQuests do
  @moduledoc """
  Returns the distinct quests this topic touches, as full `%Quest{}` structs
  sorted by quest name. Each quest appears once regardless of how many
  transitions connect to it through this topic.

  Walks through `Topic.quest_transitions` (every `Journal X N` call site
  inside a response on this topic), which has no speaker-resolution
  dependency. Topics gated only by faction/class membership (e.g. the
  Morag Tong writ family) still surface this way, where an actor-based
  path would miss them.

  Unlike `ActorsWithRoles` / `QuestsWithRoles`, there's no per-entry role
  context here — a topic doesn't have a "role" in a quest, it's just a
  label the dialogue lives under. So this calc returns a flat list of
  quest structs rather than the `%{quest, roles, primary_role}` shape used
  for the actor cross-references.
  """
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context), do: [quest_transitions: [quest: [:name]]]

  @impl true
  def calculate(topics, _opts, _context) do
    Enum.map(topics, fn topic ->
      topic.quest_transitions
      |> Enum.map(& &1.quest)
      |> Enum.uniq_by(& &1.id)
      |> Enum.sort_by(& &1.name)
    end)
  end
end
