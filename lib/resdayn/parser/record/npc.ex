defmodule Resdayn.Parser.Record.NPC do
  use Resdayn.Parser.Record

  process_basic_string "NAME", :id
  process_basic_string "FNAM", :name
  process_basic_string "MODL", :nif_model_filename
  process_basic_string "RNAM", :race_id
  process_basic_string "CNAM", :class_id
  process_basic_string "ANAM", :faction_id
  process_basic_string "BNAM", :head_model_id
  process_basic_string "KNAM", :hair_model_id
  process_basic_string "SCRI", :script_id
  process_basic_list "NPCS", :spell_ids
  process_inventory "NPCO", :inventory
  process_ai_packages()

  def process({"NPDT", value}, data) when byte_size(value) == 12 do
    <<level::uint16(), disposition::uint8(), reputation::uint8(), rank::uint8(), _::char(3),
      gold::uint32()>> = value

    record_unnested_value(data, %{
      level: level,
      disposition: disposition,
      global_reputation: reputation,
      faction_rank: rank,
      gold: gold
    })
  end

  def process({"NPDT", value}, data) when byte_size(value) == 52 do
    <<level::uint16(), str::uint8(), int::uint8(), wil::uint8(), agi::uint8(), spd::uint8(),
      endurance::uint8(), per::uint8(), luc::uint8(), skills::char(27), _::uint8(),
      health::uint16(), magicka::uint16(), fatigue::uint16(), disposition::uint8(),
      reputation::uint8(), rank::uint8(), _::uint8(), gold::uint32()>> = value

    record_unnested_value(data, %{
      level: level,
      attributes: %{
        0 => str,
        1 => int,
        2 => wil,
        3 => agi,
        4 => spd,
        5 => endurance,
        6 => per,
        7 => luc
      },
      skills: skills(skills),
      health: health,
      magicka: magicka,
      fatigue: fatigue,
      disposition: disposition,
      global_reputation: reputation,
      faction_rank: rank,
      gold: gold
    })
  end

  def process({"FLAG", <<value::uint32()>>}, data) do
    blood =
      case Enum.find(
             bitmask(value, skeleton: 0x0400, metal_sparks: 0x0800),
             fn {_key, val} -> val end
           ) do
        {key, true} -> key
        nil -> :default
      end

    data
    |> record_value(:blood, blood)
    |> record_value(
      :flags,
      bitmask(value,
        female: 0x0001,
        essential: 0x0002,
        respawn: 0x0004,
        autocalc: 0x0010
      )
    )
  end

  def process({"DODT", value}, data) do
    record_list_of_maps_key(
      data,
      :transport_options,
      :coordinates,
      coordinates(value)
    )
  end

  def process({"DNAM" = v, value}, data) do
    record_list_of_maps_value(
      data,
      :transport_options,
      :cell_id,
      printable!(__MODULE__, v, value)
    )
  end

  defp skills(bitstring) do
    skills(bitstring, %{}, 0)
  end

  defp skills(<<>>, map, 27), do: map

  defp skills(<<num::uint8(), rest::binary>>, map, index) do
    skills(rest, Map.put(map, index, num), index + 1)
  end
end
