defmodule Resdayn.Parser.Record.GameSetting do
  import Resdayn.Parser.{DataSizes, Helpers}

  @doc """
  Contains a single NAME record, then either a STRV, INTV or FLTV record.
  """
  def process(records) do
    Enum.map(records, &parse/1)
    |> Map.new()
  end

  defp parse({"NAME" = v, value}) do
    {:name, printable!(__MODULE__, v, value)}
  end

  defp parse({"STRV" = v, value}) do
    {:value, printable!(__MODULE__, v, value)}
  end

  defp parse({"FLTV", <<value::lfloat()>>}) do
    {:value, Float.round(value, 2)}
  end

  defp parse({"INTV", <<value::int()>>}) do
    {:value, value}
  end
end
