defmodule Resdayn.Parser.Subrecord do
  import Resdayn.Parser.{DataSizes, Helpers}

  def parse("TES3" = k, "HEDR" = v, value) do
    <<version::lfloat(), _unknown::long(), company::char(32), description::char(256),
      record_count::long()>> = value

    {:header,
     %{
       version: Float.round(version, 2),
       company: printable!(k, v, "company", truncate(company)),
       description: printable!(k, v, "description", truncate(description)),
       record_count: record_count
     }}
  end

  def parse("TES3" = k, "MAST" = v, value) do
    {:master, printable!(k, v, truncate(value))}
  end

  def parse("TES3", "DATA", <<value::long64()>>) do
    {:master_size, value}
  end

  def parse("GMST" = k, "NAME" = v, value) do
    {:name, printable!(k, v, truncate(value))}
  end

  def parse("GMST" = k, "STRV" = v, value) do
    {:value, printable!(k, v, truncate(value))}
  end

  def parse("GMST", "FLTV", <<value::lfloat()>>) do
    {:value, Float.round(value, 2)}
  end

  def parse("GMST", "INTV", <<value::int()>>) do
    {:value, value}
  end

  defp printable!(type, subtype, name \\ "data", string) do
    if String.printable?(string) do
      string
    else
      # Debugging to see where the unprintable value is
      for i <- 0..String.length(string) do
        if !String.printable?(string, i) do
          raise RuntimeError,
                "#{type}(#{subtype}): Unprintable value at #{name}[#{i}]: #{inspect(String.at(string, i - 1))}"
        end
      end
    end
  end
end
