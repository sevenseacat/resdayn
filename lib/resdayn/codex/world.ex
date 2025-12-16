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

    resource __MODULE__.ReferencableObject
    resource __MODULE__.Container

    resource __MODULE__.Creature do
      define :get_creature_by_id, action: :read, get_by: :id
    end

    resource __MODULE__.CreatureLevelledList

    resource __MODULE__.Region do
      define :get_region_by_id, action: :read, get_by: :id
    end

    resource __MODULE__.Cell do
      define :get_cell_by_id, action: :read, get_by: :id
    end

    resource __MODULE__.Cell.CellReference
  end
end
