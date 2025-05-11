defmodule Resdayn.Codex.Characters do
  use Ash.Domain,
    otp_app: :resdayn

  resources do
    resource Resdayn.Codex.Characters.Skill
    resource Resdayn.Codex.Characters.Class
    resource Resdayn.Codex.Characters.Class.Skill
    resource Resdayn.Codex.Characters.Faction
    resource Resdayn.Codex.Characters.Faction.Reaction
    resource Resdayn.Codex.Characters.Faction.Skill
  end
end
