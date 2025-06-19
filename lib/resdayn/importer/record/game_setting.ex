defmodule Resdayn.Importer.Record.GameSetting do
  use Resdayn.Importer.Record

  def process(records, opts) do
    records
    |> of_type(Resdayn.Parser.Record.GameSetting)
    |> Enum.map(fn record ->
      record.data
      |> Map.take([:id, :value])
      |> with_flags(:flags, record.flags)
    end)
    |> separate_for_import(Resdayn.Codex.Mechanics.GameSetting, opts)
  end
end
