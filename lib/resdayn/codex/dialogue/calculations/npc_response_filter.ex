defmodule Resdayn.Codex.Dialogue.Calculations.NPCResponseFilter do
  use Ash.Resource.Calculation

  @impl true
  def expression(_opts, context) do
    npc = Ash.get!(Resdayn.Codex.World.NPC, context.arguments.npc_id)

    expr(
      # Basic NPC identity filters
      (is_nil(speaker_npc_id) or speaker_npc_id == ^npc.id) and
        (is_nil(speaker_class_id) or speaker_class_id == ^npc.class_id) and
        (is_nil(speaker_race_id) or speaker_race_id == ^npc.race_id) and
        (is_nil(speaker_faction_id) or
           (not is_nil(^npc.faction_id) and speaker_faction_id == ^npc.faction_id))

      # To add:
      # =======
      # * Speaker faction rank
      #   Will never be specified if speaker faction is not specified
      #   NPC must be at least that rank in the specified faction
      #
      # * Gender
      #   To compare with the value located in the NPC's `npc_flags` attribute
      #   Female NPCs have `female`, male NPCs do not have a flag
      #
      # * Cell name
      #   If there are any CellReference records for the specified cell and the specified NPC
      #
      # * Extra conditions located in the `conditions` list - not all are relevant
      #   (most are player based) but the important ones are:
      #
      #   * fight, hello, alarm, flee
      #     These are all values in the NPCs `alert` attribute map
      #
      #   * not_faction, not_class, not_race, not_cell
      #     Similar to the existing checks but done via conditions
      #
      #   * local/not_local
      #     These relate to variables in the script associated to the NPC
    )
  end
end
