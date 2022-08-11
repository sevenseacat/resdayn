defmodule Resdayn.Formatter do
  alias Resdayn.Formatter.{GameSetting, Master}

  def format(%{type: "TES3"} = record), do: Master.format(record)
  def format(%{type: "GMST"} = record), do: GameSetting.format(record)

  def format(stream) when is_function(stream), do: Stream.map(stream, &format/1)
end
