defmodule Resdayn.Importer.Record.GameSetting do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    data =
      records
      |> of_type(Resdayn.Parser.Record.GameSetting)
      |> Enum.map(fn record ->
        record.data
        |> Map.take([:name, :value])
        |> with_flags(:flags, record.flags)
      end)

    %{
      resource: Resdayn.Codex.Mechanics.GameSetting,
      data: data
    }
  end
end
