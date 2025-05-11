defmodule Resdayn.Importer.Record.Faction do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    data =
      records
      |> of_type(Resdayn.Parser.Record.Faction)
      |> Enum.map(fn record ->
        record.data
        |> Map.take([:hidden, :id, :name, :skill_ids, :reactions, :ranks])
        |> Map.update(:reactions, [], fn reactions ->
          Enum.uniq_by(Enum.reverse(reactions), & &1.target_id)
        end)
        |> Map.put(:attribute1_id, Enum.at(record.data.attribute_ids, 0))
        |> Map.put(:attribute2_id, Enum.at(record.data.attribute_ids, 1))
        |> with_flags(:flags, record.flags)
      end)

    %{data: data, resource: Resdayn.Codex.Characters.Faction}
  end
end
