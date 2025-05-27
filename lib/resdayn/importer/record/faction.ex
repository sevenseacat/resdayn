defmodule Resdayn.Importer.Record.Faction do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    records
    |> of_type(Resdayn.Parser.Record.Faction)
    |> Enum.map(fn record ->
      record.data
      |> Map.take([:hidden, :id, :name, :ranks])
      |> Map.put(:attribute1_id, Enum.at(record.data.attribute_ids, 0))
      |> Map.put(:attribute2_id, Enum.at(record.data.attribute_ids, 1))
      |> with_flags(:flags, record.flags)
    end)
    |> separate_for_import(Resdayn.Codex.Characters.Faction)
  end
end
