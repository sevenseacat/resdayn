defmodule Resdayn.Codex.Characters do
  use Ash.Domain,
    otp_app: :resdayn

  resources do
    resource Resdayn.Codex.Characters.Skill
  end
end
