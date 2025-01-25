defmodule Resdayn.Codex.Mechanics do
  use Ash.Domain,
    otp_app: :resdayn

  resources do
    resource Resdayn.Codex.Mechanics.Script
  end
end
