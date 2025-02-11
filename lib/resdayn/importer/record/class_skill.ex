defmodule Resdayn.Importer.Record.ClassSkill do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    data =
      records
      |> of_type(Resdayn.Parser.Record.Class)
      |> Enum.flat_map(fn %{data: data} ->
        make_records(data.id, data.major_skill_ids, :major) ++
          make_records(data.id, data.minor_skill_ids, :minor)
      end)

    %{
      resource: Resdayn.Codex.Characters.ClassSkill,
      data: data
    }
  end

  defp make_records(class_id, skill_ids, category) do
    Enum.map(skill_ids, fn skill_id ->
      %{class_id: class_id, skill_id: skill_id, category: category}
    end)
  end
end
