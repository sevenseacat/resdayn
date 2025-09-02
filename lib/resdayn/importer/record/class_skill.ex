defmodule Resdayn.Importer.Record.ClassSkill do
  use Resdayn.Importer.Record

  @doc """
  This will run *after* the main Class importer, so all will be updates
  """
  def process(records, opts) do
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
        major_skills: major_skills,
        minor_skills: minor_skills
      }
    end)
    |> separate_for_import(
      Resdayn.Codex.Characters.Class,
      Keyword.put(opts, :action, :import_relationships)
    )
  end
end
