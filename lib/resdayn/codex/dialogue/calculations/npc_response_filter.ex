defmodule Resdayn.Codex.Dialogue.Calculations.NPCResponseFilter do
  @moduledoc """
  Calculation that determines if a dialogue response is valid for a given NPC.

  This is a database-level calculation that can be used for filtering and sorting.
  """

  use Ash.Resource.Calculation

  alias Resdayn.Codex.Dialogue.Calculations.NPCFilterHelpers

  @impl true
  def expression(_opts, context) do
    npc_id = context.arguments[:npc_id]

    if npc_id do
      case NPCFilterHelpers.fetch_npc_data(npc_id) do
        {:ok, npc_info} ->
          NPCFilterHelpers.build_filter_expression(npc_info)

        {:error, _} ->
          # NPC not found - no responses match
          expr(false)
      end
    else
      expr(true)
    end
  end
end
