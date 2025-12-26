defmodule Resdayn.Codex.NPCTest do
  use ExUnit.Case, async: false

  require Ash.Query

  describe "many_to_many with join_relationship limit (lateral join path)" do
    test "trained_skills inherits limit from trained_skill_values join_relationship" do
      # Qorwynn is a trainer with many skills, but trained_skill_values has limit: 3
      # so trained_skills (many_to_many via trained_skill_values) should only return 3 skills
      npc =
        Ash.get!(Resdayn.Codex.World.NPC, "qorwynn",
          load: [:trained_skill_values, :trained_skills]
        )

      # trained_skill_values correctly returns 3 (the limit)
      assert length(npc.trained_skill_values) == 3

      # trained_skills should also return only 3, inheriting the limit from join_relationship
      # BUG: Currently returns all skills because lateral join path doesn't apply join_relationship limit
      assert length(npc.trained_skills) == 3

      # The skills returned should correspond to the top 3 skill values
      trained_skill_ids = Enum.map(npc.trained_skill_values, & &1.skill_id)
      returned_skill_ids = Enum.map(npc.trained_skills, & &1.id)

      assert Enum.sort(returned_skill_ids) == Enum.sort(trained_skill_ids)
    end
  end
end
