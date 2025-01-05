defmodule Resdayn.Parser.Record.Creature do
  use Resdayn.Parser.Record

  @creature_types %{
    0 => :creature,
    1 => :daedra,
    2 => :undead,
    3 => :humanoid
  }

  process_basic_string "NAME", :id
  process_basic_string "MODL", :nif_model
  process_basic_string "FNAM", :name
  process_inventory "NPCO", :carried_objects

  def process({"NPDT", value}, data) do
    <<type::uint32(), level::uint32(), str::uint32(), int::uint32(), wil::uint32(), agi::uint32(),
      spd::uint32(), endurance::uint32(), per::uint32(), luc::uint32(), health::uint32(),
      magicka::uint32(), fatigue::uint32(), soul::uint32(), combat::uint32(), magic::uint32(),
      stealth::uint32(), attack1_min::uint32(), attack1_max::uint32(), attack2_min::uint32(),
      attack2_max::uint32(), attack3_min::uint32(), attack3_max::uint32(),
      gold::uint32()>> = value

    record_unnested_value(data, %{
      type: Map.fetch!(@creature_types, type),
      level: level,
      strength: str,
      intelligence: int,
      willpower: wil,
      agility: agi,
      speed: spd,
      endurance: endurance,
      personality: per,
      luck: luc,
      health: health,
      magicka: magicka,
      fatigue: fatigue,
      soul_size: soul,
      combat: combat,
      magic: magic,
      stealth: stealth,
      gold: gold,
      attacks: [
        %{min: attack1_min, max: attack1_max},
        %{min: attack2_min, max: attack2_max},
        %{min: attack3_min, max: attack3_max}
      ]
    })
  end

  def process({"FLAG", <<value::uint32()>>}, data) do
    record_value(
      data,
      :flags,
      bitmask(value,
        biped: 0x0001,
        respawn: 0x0002,
        weapon_and_shield: 0x0004,
        none: 0x0008,
        swims: 0x0010,
        flies: 0x0020,
        walks: 0x0040,
        default: 0x0048,
        essential: 0x0080,
        blood_type_1: 0x0400,
        blood_type_2: 0x0800,
        blood_type_3: 0x0C00,
        blood_type_4: 0x1000,
        blood_type_5: 0x1400,
        blood_type_6: 0x1800,
        blood_type_7: 0x1C00
      )
    )
  end

  def process({"AIDT", value}, data) do
    <<hello::uint8(), _::uint8(), fight::uint8(), flee::uint8(), alarm::uint8(), _rest::binary>> =
      value

    record_value(data, :ai_data, %{hello: hello, fight: fight, flee: flee, alarm: alarm})
  end

  def process({"AI_W", value}, data) do
    <<distance::uint16(), duration::uint16(), time_of_day::uint8(), idles::char(8), 1::uint8(),
      _rest::binary>> = value

    record_list(data, :ai_packages, %{
      type: :ai_wander,
      distance: distance,
      duration: duration(duration),
      time_of_day: time_of_day,
      idles: :binary.bin_to_list(idles)
    })
  end

  # Duration parameters in all packages are in hours. Any value greater than 24
  # should be divided by 100, and set to 24 if still greater than 24.
  defp duration(num), do: min(rem(num, 100), 24)
end
