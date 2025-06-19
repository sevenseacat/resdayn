defmodule Resdayn.Importer.Record.Tool do
  use Resdayn.Importer.Record

  def process(records, opts) do
    records
    |> of_type([
      Resdayn.Parser.Record.RepairItem,
      Resdayn.Parser.Record.Lockpick,
      Resdayn.Parser.Record.Probe
    ])
    |> Enum.map(fn record ->
      tool_type =
        case record.type do
          Resdayn.Parser.Record.RepairItem -> :repair_item
          Resdayn.Parser.Record.Lockpick -> :lockpick
          Resdayn.Parser.Record.Probe -> :probe
        end

      record.data
      |> Map.take([
        :id,
        :name,
        :weight,
        :value,
        :uses,
        :quality,
        :script_id,
        :nif_model_filename,
        :icon_filename
      ])
      |> Map.put(:type, tool_type)
      |> with_flags(:flags, record.flags)
    end)
    |> separate_for_import(Resdayn.Codex.Items.Tool, opts)
  end
end
