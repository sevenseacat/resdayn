defmodule Resdayn.Catalog.SkillTest do
  use Resdayn.IntegrationCase

  describe "`trainers` relationship" do
    def trainer_names(id) do
      skill = Ash.get!(Resdayn.Catalog.Characters.Skill, id, load: [trainers: :npc])
      Enum.map(skill.trainers, & to_string(&1.npc.id))
    end

    test "Armorer trainers - only three in the whole game" do
      names = trainer_names(1)
      assert Enum.sort(names) == ["Avus Belvilo", "ababael timsar-dadisun", "wayn"]
    end

    test "only lists NPCs for whom the skill is one of their 3 highest" do
      # Qorwynn's Alteration (11) and Conjuration (13) are both value 72, but the
      # skill_id tiebreak makes 11 his 3rd-highest skill and 13 his 4th. So he can
      # train Alteration but not Conjuration — even though his 72 in Conjuration
      # beats its actual third-best trainer. A broken top-3 rule would list him.
      alteration_trainers = trainer_names(11)
      conjuration_trainers = trainer_names(13)

      assert "qorwynn" in alteration_trainers
      refute "qorwynn" in conjuration_trainers
    end
  end
end
