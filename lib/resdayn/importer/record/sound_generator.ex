defmodule Resdayn.Importer.Record.SoundGenerator do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    records
    |> of_type(Resdayn.Parser.Record.SoundGenerator)
    |> Enum.map(fn record -> record.data end)
    |> separate_for_import(Resdayn.Codex.Assets.SoundGenerator)
  end
end
