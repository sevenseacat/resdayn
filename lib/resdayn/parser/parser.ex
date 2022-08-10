defmodule Resdayn.Parser do
  @moduledoc """
  The main module for reading data from a provided ESM file.

  File format interpreted from http://www.uesp.net/morrow/tech/mw_esm.txt
  """

  import Resdayn.Parser.{DataSizes, Helpers}

  alias Resdayn.Parser.{SubrecordValue}

  @doc """
  Return a list of records as read from the ESM file.
  """
  def read(filename) do
    filename
    |> stream()
    |> Enum.to_list()
  end

  @doc """
  Return a stream of records as read from the ESM file.
  """
  def stream(filename) do
    Stream.resource(
      fn -> File.open!(filename, [:binary]) end,
      fn file -> read_record(file) end,
      fn file -> File.close(file) end
    )
  end

  def read_record(file) do
    # Each record has a 16-byte header, immediately followed by zero or more subrecords
    case IO.binread(file, 16) do
      :eof -> {:halt, file}
      record -> {[parse_record(record, file)], file}
    end
  end

  defp parse_record(
         <<type::binary-4, subrecord_size::long, _header1::binary-4, flags::long>>,
         file
       ) do
    # The 16-byte header contains the size of the set of subrecords
    subrecords =
      file
      |> IO.binread(subrecord_size)
      |> parse_subrecords(type)

    %{
      type: type,
      flags: bitmask(flags, blocked: 0x00002000, persistent: 0x00000400),
      subrecords: subrecords
    }
  end

  defp parse_subrecords("", _type), do: []

  defp parse_subrecords(
         <<subtype::binary-4, size::long, value::binary-size(size), rest::binary>>,
         type
       ) do
    # Each subrecord has an 8-byte header which contains the size of the data, then the data for the record
    # The rest is more subrecords.
    [
      {subtype, SubrecordValue.parse(type, subtype, value)}
      | parse_subrecords(rest, type)
    ]
  end
end
