defmodule Resdayn.Importer.Record.Region do
  use Resdayn.Importer.Record

  def process(records, opts) do
    records
    |> of_type(Resdayn.Parser.Record.Region)
    |> Enum.map(fn record ->
      %{
        id: record.data.id,
        name: record.data[:name],
        disturb_sleep_creature_id: record.data[:disturb_sleep_creature_id],
        weather: record.data.weather,
        map_color: record.data[:map_color],
        sounds: transform_sounds(record.data[:sounds] || [])
      }
    end)
    |> separate_for_import(Resdayn.Codex.World.Region, opts)
  end

  defp transform_sounds(sounds) do
    sounds
    |> List.flatten()
    |> Enum.map(fn sound ->
      %{
        sound_id: sound[:id],
        chance: sound[:chance]
      }
    end)
  end
end
