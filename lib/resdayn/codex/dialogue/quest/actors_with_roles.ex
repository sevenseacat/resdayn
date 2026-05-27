defmodule Resdayn.Codex.Dialogue.Quest.ActorsWithRoles do
  @moduledoc """
  Calculation that groups a quest's actor involvements by actor, pairing each
  actor with the distinct roles they play across the quest's versions.

  Parameterised so it serves both NPCs and creatures:

      calculate :npcs_with_roles, :term,
        {__MODULE__, involvements: :npc_involvements, actor: :npc}

  Returns a list of `%{actor: actor, roles: [reason]}`, sorted by actor name.
  """
  use Ash.Resource.Calculation

  @impl true
  def load(_query, opts, _context) do
    [{opts[:involvements], [opts[:actor], :reason]}]
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
        %{
          actor: Map.fetch!(first, actor_key),
          roles: rows |> Enum.map(& &1.reason) |> Enum.uniq() |> Enum.sort()
        }
      end)
      |> Enum.sort_by(& &1.actor.name)
    end)
  end
end
