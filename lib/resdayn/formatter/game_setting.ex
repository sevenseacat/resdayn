defmodule Resdayn.Formatter.GameSetting do
  @types ~w(STRV INTV FLTV)

  def format(record) do
    %{
      type: "GMST",
      flags: flags,
      subrecords: [{"NAME", name} | maybe_value]
    } = record

    %{
      name: name,
      flags: flags,
      type: :game_setting,
      value: value(maybe_value)
    }
  end

  defp value([]), do: nil
  defp value([{type, value}]) when type in @types, do: value
end
