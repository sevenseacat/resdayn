defmodule Resdayn.Importer.Record.CreatureLevelledList do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> of_type(Resdayn.Parser.Record.CreatureLevelledList)
      |> Enum.map(fn record ->
        # Process creatures list with type resolution
        creatures =
          (record.data[:creatures] || [])
          |> Enum.map(fn creature ->
            %{
              creature_ref_id: creature.id,
              player_level: creature.player_level
            }
          end)

        record.data
        |> Map.take([:id, :chance_none, :script_id])
        |> Map.put(:for_each_item, get_in(record.data, [:flags, :for_each_item]) || false)
        |> Map.put(:creatures, creatures)
        |> Map.put(
          :from_all_lower_levels,
          get_in(record.data, [:flags, :from_all_lower_levels]) || false
        )
        |> with_flags(:flags, record.flags)
      end)

    %{
      type: :fast_bulk,
      resource: Resdayn.Codex.World.CreatureLevelledList,
      records: processed_records,
      conflict_keys: [:id]
    }
  end
end
