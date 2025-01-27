defmodule Resdayn.Importer.Record.Skill do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    data =
      records
      |> of_type(Resdayn.Parser.Record.Skill)
      |> Enum.map(fn record ->
        Map.put(record.data, :flags, record.flags)
      end)

    %{
      resource: Resdayn.Codex.Characters.Skill,
      data: data
    }
  end
end
