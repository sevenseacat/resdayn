defmodule Resdayn.Parser.Record.MainHeader do
  @moduledoc """
  Contains a single HEDR record, then pairs of MAST/DATA records that should
  be combined.
  """

  use Resdayn.Parser.Record

  def process({"HEDR" = v, value}, data) do
    <<version::float32(), flags::uint32(), company::char(32), description::char(256),
      record_count::uint32()>> = value

    header = %{
      version: float(version),
      flags: bitmask(flags, master: 0x1),
      company: printable!(__MODULE__, v, "company", company),
      description: printable!(__MODULE__, v, "description", description),
      record_count: record_count
    }

    record_value(data, :header, header)
  end

  def process({"MAST" = v, value}, data) do
    record_list_of_maps_key(data, :masters, :name, printable!(__MODULE__, v, value))
  end

  def process({"DATA", <<value::uint64()>>}, data) do
    record_list_of_maps_value(data, :masters, :size, value)
  end
end
