defmodule Resdayn.Codex.Mechanics do
  use Ash.Domain,
    otp_app: :resdayn

  resources do
    resource Resdayn.Codex.Mechanics.Attribute
    resource Resdayn.Codex.Mechanics.DataFile
    resource Resdayn.Codex.Mechanics.GameSetting
    resource Resdayn.Codex.Mechanics.Script
  end
end
