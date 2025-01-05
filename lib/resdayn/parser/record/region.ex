defmodule Resdayn.Parser.Record.Region do
  use Resdayn.Parser.Record

  def process({"NAME" = v, value}, data) do
    record_value(data, :id, printable!(__MODULE__, v, value))
  end

  def process({"FNAM" = v, value}, data) do
    record_value(data, :name, printable!(__MODULE__, v, value))
  end

  def process({"WEAT", value}, data) do
    <<clear::integer, cloudy::integer, foggy::integer, overcast::integer, rain::integer,
      thunder::integer, ash::integer, blight::integer>> = value

    record_value(data, :weather, %{
      clear: clear,
      cloudy: cloudy,
      foggy: foggy,
      overcast: overcast,
      rain: rain,
      thunder: thunder,
      ash: ash,
      blight: blight,
      snow: 0,
      blizzard: 0
    })
  end

  # what is "sleep creature"???
  def process({"BNAM" = v, value}, data) do
    record_value(data, :sleep_creature, printable!(__MODULE__, v, value))
  end

  def process({"CNAM", value}, data) do
    record_value(data, :map_color, color(value))
  end

  def process({"SNAM" = v, value}, data) do
    record_list(data, :sounds, sounds(v, value))
  end

  defp sounds(_field, <<>>), do: []

  defp sounds(field, <<name::char(32), chance::integer, rest::binary>>) do
    [%{id: printable!(__MODULE__, field, name), chance: chance} | sounds(field, rest)]
  end
end
