defmodule Resdayn.Codex.QuestAnalysis.QuestsWithRoles do
  @moduledoc """
  The inverse of `Resdayn.Codex.Dialogue.Quest.ActorsWithRoles`: given an actor
  (NPC or creature), groups that actor's involvements by quest, pairing each
  quest with the distinct roles the actor plays in it.

  Parameterised with the actor's involvements relationship:

      calculate :related_quests, :term,
        {__MODULE__, involvements: :quest_involvements}

  Returns a list of `%{quest: quest, roles: [reason]}`, sorted by quest name.
  An actor involved in several versions of the same quest collapses to one
  entry, since involvements are grouped by the player-concept `quest_id`.
  """
  use Ash.Resource.Calculation

  @impl true
  def load(_query, opts, _context) do
    [{opts[:involvements], [:quest, :reason]}]
  end

  @impl true
  def calculate(records, opts, _context) do
    involvements_key = opts[:involvements]

    Enum.map(records, fn record ->
      record
      |> Map.fetch!(involvements_key)
      |> Enum.group_by(& &1.quest_id)
      |> Enum.map(fn {_quest_id, [first | _] = rows} ->
        %{quest: first.quest, roles: rows |> Enum.map(& &1.reason) |> Enum.uniq() |> Enum.sort()}
      end)
      |> Enum.sort_by(& &1.quest.name)
    end)
  end
end
