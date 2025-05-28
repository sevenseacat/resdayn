defmodule Resdayn.Codex.World do
  use Ash.Domain,
    otp_app: :resdayn

  resources do
    resource __MODULE__.Activator
    resource __MODULE__.Door
    resource __MODULE__.InventoryItem
    resource __MODULE__.NPC
    resource __MODULE__.ReferencableObject
    resource __MODULE__.Container
  end
end
