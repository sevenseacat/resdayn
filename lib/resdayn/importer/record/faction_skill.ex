defmodule Resdayn.Importer.Record.FactionSkill do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> of_type(Resdayn.Parser.Record.Faction)
      |> Enum.map(fn record ->
        skills =
          (record.data[:skill_ids] || [])
          |> Enum.map(fn skill_id -> %{skill_id: skill_id} end)

        %{
          id: record.data.id,
          skills: skills
        }
      end)

    %{
      type: :children,
      parent_resource: Resdayn.Catalog.Characters.Faction,
      related_resource: Resdayn.Catalog.Characters.Faction.Skill,
      parent_key: :faction_id,
      id_field: :skill_id,
      relationship_key: :skills,
      on_missing: :destroy,
      records: processed_records
    }
  end
end
