defmodule Resdayn.Importer.Record.FactionReaction do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> of_type(Resdayn.Parser.Record.Faction)
      |> Enum.map(fn record ->
        reactions =
          (record.data[:reactions] || [])
          |> Enum.reverse()
          |> Enum.uniq_by(& &1.target_id)
          |> Enum.map(fn reaction ->
            %{target_id: reaction.target_id, adjustment: reaction.adjustment}
          end)

        %{
          id: record.data.id,
          reactions: reactions
        }
      end)

    %{
      type: :bulk_relationship,
      parent_resource: Resdayn.Codex.Characters.Faction,
      related_resource: Resdayn.Codex.Characters.Faction.Reaction,
      parent_key: :source_id,
      id_field: :target_id,
      relationship_key: :reactions,
      on_missing: :destroy,
      records: processed_records
    }
  end
end
