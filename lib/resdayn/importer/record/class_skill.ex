defmodule Resdayn.Importer.Record.ClassSkill do
  use Resdayn.Importer.Record

  @doc """
  This will run *after* the main Class importer, so all will be updates
  """
  def process(records, opts) do
    records
    |> of_type(Resdayn.Parser.Record.Class)
    |> Enum.map(fn record ->
      Map.take(record.data, [:id, :major_skill_ids, :minor_skill_ids])
    end)
    |> separate_for_import(
      Resdayn.Codex.Characters.Class,
      Keyword.put(opts, :action, :import_relationships)
    )
  end
end
