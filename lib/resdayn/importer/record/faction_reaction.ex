defmodule Resdayn.Importer.Record.FactionReaction do
  use Resdayn.Importer.Record

  def process(records, opts) do
    records
    |> of_type(Resdayn.Parser.Record.Faction)
    |> Enum.map(fn record ->
      record.data
      |> Map.take([:id, :skill_ids, :reactions])
      |> Map.update(:reactions, [], fn reactions ->
        Enum.uniq_by(Enum.reverse(reactions), & &1.target_id)
      end)
    end)
    |> separate_for_import(
      Resdayn.Codex.Characters.Faction,
      Keyword.put(opts, :action, :import_relationships)
    )
  end
end
