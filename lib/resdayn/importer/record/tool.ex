defmodule Resdayn.Importer.Record.Tool do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    data =
      records
      |> Enum.filter(fn record ->
        record.type in [
          Resdayn.Parser.Record.RepairItem,
          Resdayn.Parser.Record.Lockpick,
          Resdayn.Parser.Record.Probe
        ]
      end)
      |> Enum.map(fn record ->
        tool_type = case record.type do
          Resdayn.Parser.Record.RepairItem -> :repair_item
          Resdayn.Parser.Record.Lockpick -> :lockpick
          Resdayn.Parser.Record.Probe -> :probe
        end

        record.data
        |> Map.take([:id, :name, :weight, :value, :uses, :quality, :script_id])
        |> Map.put(:tool_type, tool_type)
        |> Map.put(:nif_model_filename, record.data.nif_model)
        |> Map.put(:icon_filename, record.data.icon)
        |> with_flags(:flags, record.flags)
      end)

    %{
      resource: Resdayn.Codex.Items.Tool,
      data: data
    }
  end
end