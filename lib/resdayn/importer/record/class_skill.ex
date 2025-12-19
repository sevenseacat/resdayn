defmodule Resdayn.Importer.Record.ClassSkill do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> of_type(Resdayn.Parser.Record.Class)
      |> Enum.map(fn record ->
        major_skills =
          (record.data.major_skill_ids || [])
          |> Enum.map(fn skill_id -> %{skill_id: skill_id, category: :major} end)

        minor_skills =
          (record.data.minor_skill_ids || [])
          |> Enum.map(fn skill_id -> %{skill_id: skill_id, category: :minor} end)

        %{
          id: record.data.id,
          skills: major_skills ++ minor_skills
        }
      end)

    %{
      type: :bulk_relationship,
      parent_resource: Resdayn.Codex.Characters.Class,
      related_resource: Resdayn.Codex.Characters.Class.Skill,
      parent_key: :class_id,
      id_field: :skill_id,
      relationship_key: :skills,
      on_missing: :destroy,
      records: processed_records
    }
  end
end
