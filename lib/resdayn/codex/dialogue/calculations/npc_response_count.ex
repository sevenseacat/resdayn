defmodule Resdayn.Codex.Dialogue.Calculations.NPCResponseCount do
  @moduledoc """
  Calculation that counts dialogue responses valid for a given NPC.

  This is a database-level calculation that produces an efficient SQL count
  with the NPC filter conditions pushed down to the database.
  """

  use Ash.Resource.Calculation

  alias Resdayn.Codex.Dialogue.Calculations.NPCFilterHelpers

  @impl true
  def expression(_opts, context) do
    npc_id = context.arguments[:npc_id]

    if npc_id do
      case NPCFilterHelpers.fetch_npc_data(npc_id) do
        {:ok, npc_info} ->
          build_count_expression(npc_info)

        {:error, _} ->
          # NPC not found - count is 0
          expr(0)
      end
    else
      # No NPC filter - return total response count
      expr(count(responses))
    end
  end

  defp build_count_expression(npc) do
    # Build a count expression that filters responses by NPC compatibility
    # Uses the same logic as NPCFilterHelpers.build_filter_expression but
    # wrapped in a count aggregate

    faction_id_list = if npc.faction_id, do: [npc.faction_id], else: []

    expr(
      count(responses,
        query: [
          filter:
            is_nil(speaker_creature_id) and
              (is_nil(speaker_npc_id) or speaker_npc_id == ^npc.id) and
              (is_nil(speaker_class_id) or speaker_class_id == ^npc.class_id) and
              (is_nil(speaker_race_id) or speaker_race_id == ^npc.race_id) and
              (is_nil(speaker_faction_id) or speaker_faction_id in ^faction_id_list) and
              (is_nil(speaker_faction_rank) or speaker_faction_rank <= ^npc.faction_rank) and
              (is_nil(cell_name) or cell_name in ^npc.cell_names) and
              (is_nil(gender) or
                 (gender == :male and not (^npc.is_female)) or
                 (gender == :female and ^npc.is_female))
        ]
      )
    )
  end
end
