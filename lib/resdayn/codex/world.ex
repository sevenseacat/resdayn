defmodule Resdayn.Codex.World do
  use Ash.Domain,
    otp_app: :resdayn

  resources do
    resource __MODULE__.Activator
    resource __MODULE__.Door
    resource __MODULE__.NPC
  end
end
