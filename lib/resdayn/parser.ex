defmodule Resdayn.Parser do
  @moduledoc """
  The main module for reading data from a provided ESM file.

  File format interpreted from http://www.uesp.net/morrow/tech/mw_esm.txt
  """

  import Resdayn.Parser.{DataSizes, Helpers}
  alias Resdayn.Parser.Record

  @doc """
  Parse all records from a binary.
  """
  def read_binary(binary) do
    parse_all_records(binary, [])
  end

  @doc """
  Return a stream of records as read from the ESM file.
  """
  def read(filename) do
    Stream.resource(
      fn -> File.open!(filename, [:binary]) end,
      fn file -> read_record(file) end,
      fn file -> File.close(file) end
    )
  end

  defp read_record(file) do
    # Each record has a 16-byte header, immediately followed by zero or more subrecords
    case IO.binread(file, 16) do
      :eof -> {:halt, file}
      record -> {[parse_record(file, record)], file}
    end
  end

  defp parse_record(
         file,
         <<type_raw::char(4), subrecord_size::uint32(), _header1::char(4), flags::uint32()>>
       ) do
    build_record(type_raw, flags, IO.binread(file, subrecord_size))
  end

  defp parse_all_records(<<>>, acc), do: Enum.reverse(acc)

  defp parse_all_records(
         <<type_raw::char(4), subrecord_size::uint32(), _header1::char(4), flags::uint32(),
           subrecord_data::char(subrecord_size), rest::binary>>,
         acc
       ) do
    parse_all_records(rest, [build_record(type_raw, flags, subrecord_data) | acc])
  end

  defp build_record(type_raw, flags, subrecord_data) do
    type = Record.to_module(type_raw)
    subrecords = parse_subrecords(subrecord_data)

    %{
      type: type,
      flags:
        bitmask(flags, blocked: 0x2000, persistent: 0x400, disabled: 0x0800, deleted: 0x0020),
      data: apply(type, :process, [subrecords])
    }
  end

  defp parse_subrecords(<<>>), do: []

  defp parse_subrecords(<<subtype::char(4), size::uint32(), value::char(size), rest::binary>>) do
    # Each subrecord has an 8-byte header which contains the size of the data, then the data for the record
    # The rest is more subrecords.
    # Don't attempt to convert the data to anything meaningful yet
    [{subtype, value} | parse_subrecords(rest)]
  end
end
