defmodule Resdayn.Catalog.QuestAnalysis.Transition.Flag do
  @moduledoc """
  Edge-level roles a transition can carry in the quest state machine.

  Only `:start` exists today (an entry point into the quest). Finish and
  restart are properties of the journal entry (the node), not the transition,
  so they live on `JournalEntry`, not here. Future *edge* roles can join this
  list.
  """
  use Ash.Type.Enum, values: [:start]
end
