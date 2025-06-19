defmodule Resdayn.Importer.Record.Sound do
  use Resdayn.Importer.Record

  def process(records, opts) do
    records
    |> of_type(Resdayn.Parser.Record.Sound)
    |> Enum.map(fn record ->
      %{
        id: record.data.id,
        filename: record.data[:filename],
        volume: record.data.attenuation.volume,
        range: [record.data.attenuation.min_range, record.data.attenuation.max_range]
      }
      |> with_flags(:flags, record.flags)
    end)
    |> separate_for_import(Resdayn.Codex.Assets.Sound, opts)
  end
end
