defmodule Resdayn.Codex.Assets do
  use Ash.Domain,
    otp_app: :resdayn

  resources do
    resource Resdayn.Codex.Assets.Sound
  end
end
