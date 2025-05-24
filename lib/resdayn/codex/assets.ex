defmodule Resdayn.Codex.Assets do
  use Ash.Domain,
    otp_app: :resdayn

  resources do
    resource __MODULE__.Sound
    resource __MODULE__.StaticObject
    resource __MODULE__.Activator
    resource __MODULE__.Light
  end
end
