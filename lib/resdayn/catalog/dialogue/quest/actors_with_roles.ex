defmodule Resdayn.Catalog.Dialogue.Quest.ActorsWithRoles do
  @moduledoc """
  Calculation that groups a quest's actor involvements by actor, pairing each
  actor with the distinct roles they play across the quest's versions.

  Parameterised so it serves both NPCs and creatures:

      calculate :npcs_with_roles, :term,
        {__MODULE__, involvements: :npc_involvements, actor: :npc}

  Returns a list of `%{actor: actor, roles: [reason], primary_role: reason}`.
  Each actor's `roles` and the list itself are ordered by involvement
  importance (see `Reason.by_importance/0`), with actor name as a tiebreaker,
  so the most central actors surface first.
  """
  use Ash.Resource.Calculation

  alias Resdayn.Catalog.QuestAnalysis.ActorInvolvement.Reason

  @impl true
  def load(_query, opts, _context) do
    [{opts[:involvements], [:reason, {opts[:actor], [:name]}]}]
  end

  @impl true
  def calculate(records, opts, _context) do
    actor_key = opts[:actor]
    involvements_key = opts[:involvements]

    Enum.map(records, fn record ->
      record
      |> Map.fetch!(involvements_key)
      |> Enum.group_by(fn row -> Map.fetch!(row, actor_key).id end)
      |> Enum.map(fn {_id, [first | _] = rows} ->
        roles =
          rows
          |> Enum.map(& &1.reason)
          |> Enum.uniq()
          |> Enum.sort_by(&Reason.importance/1)

        %{
          actor: Map.fetch!(first, actor_key),
          roles: roles,
          primary_role: hd(roles)
        }
      end)
      |> Enum.sort_by(&{Reason.importance(&1.primary_role), &1.actor.name})
    end)
  end
end
