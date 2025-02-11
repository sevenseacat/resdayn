defmodule Resdayn.Codex.Characters do
  use Ash.Domain,
    otp_app: :resdayn

  resources do
    resource Resdayn.Codex.Characters.Skill
    resource Resdayn.Codex.Characters.Class
    resource Resdayn.Codex.Characters.ClassSkill
  end
end
