defmodule Resdayn.Importer.Record.SoundGenerator do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    records
    |> of_type(Resdayn.Parser.Record.SoundGenerator)
    |> Enum.map(fn record ->
      # One Bloodmoon record is missing an ID for some reason
      Map.update!(record.data, :id, fn val ->
        val || "BM_horker_0002"
      end)
    end)
    |> separate_for_import(Resdayn.Codex.Assets.SoundGenerator)
  end
end
