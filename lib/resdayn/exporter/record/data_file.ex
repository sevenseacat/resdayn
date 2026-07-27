defmodule Resdayn.Exporter.Record.DataFile do
  @moduledoc """
  Encodes a `Resdayn.Catalog.Mechanics.DataFile` resource as a TES3 header record.
  """

  import Resdayn.Parser.DataSizes
  import Resdayn.Exporter.Helpers

  def encode(data_file, record_count: record_count) do
    version = Decimal.to_float(data_file.version)
    master_flag = if data_file.master, do: 0x1, else: 0

    hedr =
      {"HEDR",
       <<version::float32(), master_flag::uint32(), pad_string(data_file.company, 32)::binary,
         pad_string(data_file.description, 256)::binary, record_count::uint32()>>}

    master_subrecords =
      Enum.flat_map(data_file.dependencies, fn dep ->
        [
          {"MAST", null_terminate(dep.filename)},
          {"DATA", <<dep.size::uint64()>>}
        ]
      end)

    {"TES3", %{}, [hedr | master_subrecords]}
  end
end
