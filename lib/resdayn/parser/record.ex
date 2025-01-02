defmodule Resdayn.Parser.Record do
  @types %{
    "TES3" => MainHeader
  }

  @doc """
  Convert a record type string into a meaningful constant.
  """
  def parse(type) do
    Map.fetch!(@types, type)
  end

  @doc """
  Post-process a complete set of subrecords for a given record type.

  Some may contain meaningful collections of data, eg. a TES3 record
  contains pairs of dependency name/sizes that should be combined
  """
  def process_subrecords("TES3", subrecords) do
    {header, records} = Keyword.pop(subrecords, :header)

    masters =
      records
      |> Enum.chunk_every(2)
      |> Enum.map(fn group ->
        %{name: Keyword.fetch!(group, :master), size: Keyword.fetch!(group, :master_size)}
      end)

    [header: header, masters: masters]
  end
end
