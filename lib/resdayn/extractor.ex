defmodule Resdayn.Extractor do
  @moduledoc """
  The main module for reading files from a provided BSA file.

  File format interpreted from https://en.uesp.net/wiki/Morrowind_Mod:BSA_File_Format
  """

  import Resdayn.Parser.DataSizes

  @doc """
  Return a list of records as read from the ESM file.
  """
  def read(filename, output_dir \\ "output") do
    output_dir = Path.join(Path.dirname(filename), output_dir)
    file = File.open!(filename, [:binary])
    {directory_size, num_records} = read_header(file)

    Map.new()
    |> read_record_sizes(file, num_records)
    |> read_names(file, num_records, directory_size)
    |> read_files(file, output_dir)

    # All done!
    :eof = IO.binread(file, 1)

    :ok
  end

  defp read_header(file) do
    <<0x00000100::uint32(), directory_size::uint32(), num_files::uint32()>> = IO.binread(file, 12)
    {directory_size, num_files}
  end

  defp read_record_sizes(records, file, num_records) do
    Enum.reduce(1..num_records, records, fn index, records ->
      <<size::uint32(), file_offset::uint32()>> = IO.binread(file, 8)
      Map.put(records, index, %{size: size, offset: file_offset})
    end)
  end

  defp read_names(records, file, num_records, directory_size) do
    # Skip over the name offset section - don't need it
    IO.binread(file, num_records * 4)

    # Read the whole set of names - null-terminated records
    IO.binread(file, directory_size - num_records * 12)
    |> String.split(<<0>>, trim: true)
    |> Enum.with_index(1)
    |> Enum.reduce(records, fn {name, index}, records ->
      name = String.replace(name, "\\", "/")
      Map.update!(records, index, &Map.put(&1, :name, name))
    end)
  end

  defp read_files(records, file, output_dir) do
    # Skip over the hash table section - don't need it
    IO.binread(file, map_size(records) * 8)

    File.mkdir_p!(output_dir)

    records
    |> Map.to_list()
    |> Enum.sort_by(fn {_, record} -> record.offset end)
    |> Enum.map(fn {index, record} ->
      folder = Path.dirname(record.name)
      File.mkdir_p!(Path.join(output_dir, folder))

      data = IO.binread(file, record.size)
      File.write!(Path.join(output_dir, record.name), data)

      {index, Map.merge(record, %{data: data})}
    end)
    |> Map.new()
  end
end
