defmodule Resdayn.Codex.Characters do
  use Ash.Domain,
    otp_app: :resdayn

  resources do
    resource __MODULE__.Skill
    resource __MODULE__.Class
    resource __MODULE__.Class.Skill
    resource __MODULE__.Faction
    resource __MODULE__.Faction.Reaction
    resource __MODULE__.Faction.Skill
    resource __MODULE__.Race
    resource __MODULE__.Race.SkillBonus
    resource __MODULE__.Birthsign
    resource __MODULE__.BodyPart
  end
end
