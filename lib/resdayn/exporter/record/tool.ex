defmodule Resdayn.Exporter.Record.Tool do
  @moduledoc """
  Encodes a `Resdayn.Codex.Items.Tool` resource as a REPA, LOCK, or PROB record.
  """

  import Resdayn.Parser.DataSizes
  import Resdayn.Exporter.Helpers

  def encode(tool) do
    {type_code, data_subrecord} = encode_data(tool)

    subrecords =
      [
        {"NAME", null_terminate(tool.id)},
        {"MODL", null_terminate(tool.nif_model_filename)},
        {"FNAM", null_terminate(tool.name)},
        {"ITEX", null_terminate(tool.icon_filename)},
        if(tool.script_id, do: {"SCRI", null_terminate(tool.script_id)}),
        data_subrecord
      ]
      |> Enum.reject(&is_nil/1)

    {type_code, %{}, subrecords}
  end

  defp encode_data(%{type: :repair_item} = tool) do
    {"REPA",
     {"RIDT",
      <<tool.weight::float32(), tool.value::uint32(), tool.uses::uint32(),
        tool.quality::float32()>>}}
  end

  defp encode_data(%{type: :lockpick} = tool) do
    {"LOCK",
     {"LKDT",
      <<tool.weight::float32(), tool.value::uint32(), tool.quality::float32(),
        tool.uses::uint32()>>}}
  end

  defp encode_data(%{type: :probe} = tool) do
    {"PROB",
     {"PBDT",
      <<tool.weight::float32(), tool.value::uint32(), tool.quality::float32(),
        tool.uses::uint32()>>}}
  end
end
