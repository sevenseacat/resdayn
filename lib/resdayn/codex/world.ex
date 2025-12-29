defmodule Resdayn.Codex.World do
  use Ash.Domain,
    otp_app: :resdayn

  resources do
    resource __MODULE__.Activator
    resource __MODULE__.Door
    resource __MODULE__.InventoryItem

    resource __MODULE__.NPC do
      define :list_npcs, action: :read
      define :get_npc_by_id, action: :read, get_by: :id
    end

    resource __MODULE__.NPC.SkillValue do
      define :trainers_for_skill, action: :trainers_for_skill, args: [:skill_id, :base_game_only]
    end

    resource __MODULE__.ReferencableObject
    resource __MODULE__.Container

    resource __MODULE__.Creature do
      define :get_creature_by_id, action: :read, get_by: :id
    end

    resource __MODULE__.CreatureLevelledList do
      define :get_creature_levelled_list_by_id, action: :read, get_by: :id
    end

    resource __MODULE__.Region do
      define :list_regions, action: :read
      define :get_region_by_id, action: :read, get_by: :id
    end

    resource __MODULE__.Cell do
      define :get_cell_by_id, action: :read, get_by: :id
      define :named_cells_in_region, action: :named_cells_in_region, args: [:region_id]
    end

    resource __MODULE__.Cell.CellReference
  end
end
