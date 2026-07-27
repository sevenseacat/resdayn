defmodule Resdayn.Exporter do
  @moduledoc """
  The main module for writing database records to an ESP file.

  File format interpreted from http://www.uesp.net/morrow/tech/mw_esm.txt
  """

  import Resdayn.Parser.DataSizes
  alias Resdayn.Exporter.Helpers

  def build([data_file | records]) do
    encoded_records = Enum.flat_map(records, &encode_record/1)
    header = encode_record(data_file, record_count: length(encoded_records))

    raw_content = Enum.map(header ++ encoded_records, &frame_record/1)

    {:ok, IO.iodata_to_binary(raw_content)}
  end

  defp encode_record(resource, opts \\ []) do
    encoder = Resdayn.Exporter.Record.encoder_for(resource.__struct__)
    encoder.encode(resource, opts) |> List.wrap()
  end

  defp frame_record({type_code, flags_map, subrecords}) do
    framed_subrecords = Enum.map(subrecords, &frame_subrecord/1)
    subrecord_size = IO.iodata_length(framed_subrecords)

    flags =
      Helpers.encode_bitmask(
        flags_map,
        blocked: 0x2000,
        persistent: 0x400,
        disabled: 0x0800,
        deleted: 0x0020
      )

    [
      <<type_code::binary-size(4), subrecord_size::uint32(), 0::uint32(), flags::uint32()>>,
      framed_subrecords
    ]
  end

  defp frame_subrecord({subtype, data}) do
    [<<subtype::binary-size(4), byte_size(data)::uint32()>>, data]
  end
end
