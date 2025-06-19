defmodule Resdayn.Codex.Events do
  use Ash.Domain,
    otp_app: :resdayn

  resources do
    resource Resdayn.Codex.Events.ImportEvent
  end
end
