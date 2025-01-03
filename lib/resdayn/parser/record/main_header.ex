defmodule Resdayn.Parser.Record.MainHeader do
  import Resdayn.Parser.{DataSizes, Helpers}

  @doc """
  Contains a single HEDR record, then pairs of MAST/DATA records that should
  be combined.
  """
  def process(records) do
    [header | masters] = Enum.map(records, &parse/1)

    masters =
      masters
      |> Enum.chunk_every(2)
      |> Enum.map(fn [name, size] ->
        %{name: name, size: size}
      end)

    %{header: header, masters: masters}
  end

  def parse({"HEDR" = v, value}) do
    <<version::lfloat(), flags::long(), company::char(32), description::char(256),
      record_count::long()>> = value

    %{
      version: Float.round(version, 2),
      flags: bitmask(flags, master: 0x1),
      company: printable!(__MODULE__, v, "company", company),
      description: printable!(__MODULE__, v, "description", description),
      record_count: record_count
    }
  end

  def parse({"MAST" = v, value}) do
    printable!(__MODULE__, v, value)
  end

  def parse({"DATA", <<value::long64()>>}) do
    value
  end
end
