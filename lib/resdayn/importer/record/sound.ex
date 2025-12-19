defmodule Resdayn.Importer.Record.Sound do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
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

    %{
      type: :fast_bulk,
      resource: Resdayn.Codex.Assets.Sound,
      records: processed_records,
      conflict_keys: [:id]
    }
  end
end
