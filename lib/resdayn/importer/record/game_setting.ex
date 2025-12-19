defmodule Resdayn.Importer.Record.GameSetting do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    processed_records =
      records
      |> of_type(Resdayn.Parser.Record.GameSetting)
      |> Enum.map(fn record ->
        record.data
        |> Map.take([:id, :value])
        |> with_flags(:flags, record.flags)
      end)

    %{
      type: :fast_bulk,
      resource: Resdayn.Codex.Mechanics.GameSetting,
      records: processed_records,
      conflict_keys: [:id]
    }
  end
end
