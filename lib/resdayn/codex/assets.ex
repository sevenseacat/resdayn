defmodule Resdayn.Codex.Assets do
  use Ash.Domain,
    otp_app: :resdayn

  resources do
    resource Resdayn.Codex.Assets.Sound
    resource Resdayn.Codex.Assets.StaticObject
    resource Resdayn.Codex.Assets.Activator
    resource Resdayn.Codex.Assets.Light
  end
end
