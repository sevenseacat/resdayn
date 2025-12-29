defmodule Resdayn.Codex.Characters do
  use Ash.Domain,
    otp_app: :resdayn

  resources do
    resource __MODULE__.Skill do
      define :list_skills, action: :read
    end

    resource __MODULE__.Class do
      define :list_classes, action: :read
      define :get_class_by_id, action: :read, get_by: :id
    end

    resource __MODULE__.Class.Skill
    resource __MODULE__.Faction.Reaction
    resource __MODULE__.Faction.Skill

    resource __MODULE__.Race do
      define :list_races, action: :read
      define :get_race_by_id, action: :read, get_by: :id
    end

    resource __MODULE__.Race.SkillBonus

    resource __MODULE__.Birthsign do
      define :list_birthsigns, action: :read
      define :get_birthsign_by_id, action: :read, get_by: :id
    end

    resource __MODULE__.BodyPart

    resource __MODULE__.Faction do
      define :get_faction_by_id, action: :read, get_by: :id
    end
  end
end
