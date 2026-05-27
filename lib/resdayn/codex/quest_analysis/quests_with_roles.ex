defmodule Resdayn.Codex.QuestAnalysis.QuestsWithRoles do
  @moduledoc """
  The inverse of `Resdayn.Codex.Dialogue.Quest.ActorsWithRoles`: given an actor
  (NPC or creature), groups that actor's involvements by quest, pairing each
  quest with the distinct roles the actor plays in it.

  Parameterised with the actor's involvements relationship:

      calculate :related_quests, :term,
        {__MODULE__, involvements: :quest_involvements}

  Returns a list of `%{quest: quest, roles: [reason], primary_role: reason}`.
  Each quest's `roles` and the list itself are ordered by involvement
  importance (see `Reason.by_importance/0`), with quest name as a tiebreaker,
  so the quests where the actor matters most surface first. An actor involved
  in several versions of the same quest collapses to one entry, grouped by the
  player-concept `quest_id`.
  """
  use Ash.Resource.Calculation

  alias Resdayn.Codex.QuestAnalysis.ActorInvolvement.Reason

  @impl true
  def load(_query, opts, _context) do
    [{opts[:involvements], [:reason, {:quest, [:name]}]}]
  end

  @impl true
  def calculate(records, opts, _context) do
    involvements_key = opts[:involvements]

    Enum.map(records, fn record ->
      record
      |> Map.fetch!(involvements_key)
      |> Enum.group_by(& &1.quest_id)
      |> Enum.map(fn {_quest_id, [first | _] = rows} ->
        roles =
          rows
          |> Enum.map(& &1.reason)
          |> Enum.uniq()
          |> Enum.sort_by(&Reason.importance/1)

        %{
          quest: first.quest,
          roles: roles,
          primary_role: hd(roles)
        }
      end)
      |> Enum.sort_by(&{Reason.importance(&1.primary_role), &1.quest.name})
    end)
  end
end
