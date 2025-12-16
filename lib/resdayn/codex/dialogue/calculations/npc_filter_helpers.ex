defmodule Resdayn.Codex.Dialogue.Calculations.NPCFilterHelpers do
  @moduledoc """
  Shared helper functions for NPC-based dialogue filtering.

  This module provides the core logic for determining which dialogue responses
  are valid for a given NPC, used by both the `valid_for_npc?` calculation on
  Response and the `filtered_response_count` calculation on Topic.
  """

  import Ash.Expr

  @doc """
  Fetches and caches NPC data needed for filtering.

  Uses process dictionary to cache the NPC data within the same request,
  preventing repeated database lookups when Ash evaluates expressions multiple times.
  """
  def fetch_npc_data(npc_id) do
    cache_key = {:npc_filter_cache, npc_id}

    case Process.get(cache_key) do
      nil ->
        data = do_fetch_npc_data(npc_id)
        Process.put(cache_key, data)
        data

      cached ->
        cached
    end
  end

  defp do_fetch_npc_data(npc_id) do
    case Ash.get(Resdayn.Codex.World.NPC, npc_id, load: [:cell_references]) do
      {:ok, npc} ->
        # Pre-compute the cell names where this NPC exists
        npc_cell_names =
          npc.cell_references
          |> Ash.load!(:cell)
          |> Enum.map(& &1.cell.name)
          |> Enum.reject(&is_nil/1)

        {:ok,
         %{
           id: npc.id,
           class_id: npc.class_id,
           race_id: npc.race_id,
           faction_id: npc.faction_id,
           faction_rank: npc.faction_rank || 0,
           is_female: :female in npc.npc_flags,
           cell_names: npc_cell_names
         }}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Builds an Ash filter expression for matching responses to an NPC.

  The expression checks:
  - Response is not for a creature (creatures and NPCs are mutually exclusive)
  - Speaker NPC matches (or response has no NPC requirement)
  - Speaker class matches (or response has no class requirement)
  - Speaker race matches (or response has no race requirement)
  - Speaker faction matches (or response has no faction requirement)
  - Speaker faction rank is met (NPC rank >= required rank)
  - Cell name matches (NPC is placed in the required cell)
  - Gender matches (or response has no gender requirement)
  """
  def build_filter_expression(npc) do
    # For nullable NPC fields, we wrap them in a list and use `in` operator
    # instead of `==`. This avoids the "comparing with nil" warning because
    # `field in [nil]` is valid SQL (though always false for non-null fields)
    # and `field in ["value"]` works like equality.
    #
    # For faction specifically: if NPC has no faction, responses requiring
    # a faction should NOT match (speaker_faction_id must be nil)
    faction_id_list = if npc.faction_id, do: [npc.faction_id], else: []

    expr(
      # Responses for creatures should not match NPCs
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
    )
  end
end
