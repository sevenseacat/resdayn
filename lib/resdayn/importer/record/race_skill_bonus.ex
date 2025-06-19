defmodule Resdayn.Importer.Record.RaceSkillBonus do
  use Resdayn.Importer.Record

  def process(records, opts) do
    records
    |> of_type(Resdayn.Parser.Record.Race)
    |> Enum.map(fn record ->
      record.data
      |> Map.take([:id, :skill_bonuses])
    end)
    |> separate_for_import(
      Resdayn.Codex.Characters.Race,
      Keyword.put(opts, :action, :import_relationships)
    )
  end
end
