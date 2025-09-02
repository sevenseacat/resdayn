defmodule Resdayn.Importer.Record.RaceSkillBonus do
  use Resdayn.Importer.Record

  def process(records, opts) do
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
    |> separate_for_import(
      Resdayn.Codex.Characters.Race,
      Keyword.put(opts, :action, :import_relationships)
    )
  end
end
