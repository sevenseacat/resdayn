defmodule Resdayn.Parser.SubrecordValue do
  import Resdayn.Parser.{DataSizes, Helpers}

  def parse(
        "TES3",
        "HEDR",
        <<version::lfloat, _::long, company::binary-32, description::binary-256,
          record_count::long>>
      ) do
    %{
      version: Float.round(version, 2),
      company: truncate(company),
      description: truncate(description),
      record_count: record_count
    }
  end

  def parse("TES3", "MAST", value), do: truncate(value)

  def parse("TES3", "DATA", <<value::long64>>), do: value

  def parse("GMST", "FLTV", <<value::lfloat>>), do: value

  def parse("GMST", "INTV", <<value::long>>), do: value

  def parse(_, _, value), do: value
end
