defmodule Resdayn.Importer.Record.CreatureLevelledList do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> of_type(Resdayn.Parser.Record.CreatureLevelledList)
      |> Enum.map(fn record ->
        entries =
          (record.data[:creatures] || [])
          |> Enum.map(fn creature ->
            %{
              object_ref_id: creature.id,
              player_level: creature.player_level
            }
          end)

        record.data
        |> Map.take([:id, :chance_none, :script_id])
        |> Map.put(:entries, entries)
        |> Map.put(
          :from_all_lower_levels,
          get_in(record.data, [:flags, :from_all_lower_levels]) || false
        )
        |> with_flags(:flags, record.flags)
      end)

    %{
      type: :record,
      resource: Resdayn.Catalog.World.CreatureLevelledList,
      records: processed_records,
      conflict_keys: [:id]
    }
  end
end
