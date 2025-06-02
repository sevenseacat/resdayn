defmodule Resdayn.Codex.Dialogue.Calculations.NPCResponseFilter do
  use Ash.Resource.Calculation

  @impl true
  def expression(_opts, context) do
    npc_id = context.arguments[:npc_id]

    if npc_id do
      npc = Ash.get!(Resdayn.Codex.World.NPC, npc_id)

      expr(
        # Basic NPC identity filters
        (is_nil(speaker_npc_id) or speaker_npc_id == ^npc.id) and
          (is_nil(speaker_class_id) or speaker_class_id == ^npc.class_id) and
          (is_nil(speaker_race_id) or speaker_race_id == ^npc.race_id) and
          (is_nil(speaker_faction_id) or
             (not is_nil(^npc.faction_id) and speaker_faction_id == ^npc.faction_id)) and
          (is_nil(speaker_faction_rank) or speaker_faction_rank <= ^npc.faction_rank) and
          (is_nil(cell_name) or exists(cell_references, reference_id == ^npc.id)) and
          cond do
            gender == :male -> :female not in ^npc.npc_flags
            gender == :female -> :female in ^npc.npc_flags
            true -> true
          end
      )

      # To add:
      # =======
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
      #     probably the only useful one we can use is nolore
    else
      expr(true)
    end
  end
end
