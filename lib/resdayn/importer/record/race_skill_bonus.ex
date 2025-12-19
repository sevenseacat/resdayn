defmodule Resdayn.Importer.Record.RaceSkillBonus do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> of_type(Resdayn.Parser.Record.Race)
      |> Enum.map(fn record ->
        skill_bonuses =
          (record.data.skill_bonuses || [])
          |> Enum.map(fn %{skill_id: skill_id, bonus: bonus} ->
            %{skill_id: skill_id, bonus: bonus}
          end)

        %{
          id: record.data.id,
          skill_bonuses: skill_bonuses
        }
      end)

    %{
      type: :bulk_relationship,
      parent_resource: Resdayn.Codex.Characters.Race,
      related_resource: Resdayn.Codex.Characters.Race.SkillBonus,
      parent_key: :race_id,
      id_field: :skill_id,
      relationship_key: :skill_bonuses,
      on_missing: :destroy,
      records: processed_records
    }
  end
end
