defmodule Resdayn.Parser.Record.DialogueResponse do
  use Resdayn.Parser.Record

  @functions %{
    "00" => :rank_low,
    "01" => :rank_high,
    "02" => :rank_requirement,
    "03" => :reputation,
    "04" => :health_percent,
    "05" => :pc_reputation,
    "06" => :pc_level,
    "07" => :pc_health_percent,
    "08" => :pc_magicka,
    "09" => :pc_fatigue,
    "10" => :pc_strength,
    "11" => :pc_block,
    "12" => :pc_armorer,
    "13" => :pc_medium_armor,
    "14" => :pc_heavy_armor,
    "15" => :pc_blunt_weapon,
    "16" => :pc_long_blade,
    "17" => :pc_axe,
    "18" => :pc_spear,
    "19" => :pc_athletics,
    "20" => :pc_enchant,
    "21" => :pc_destruction,
    "22" => :pc_alteration,
    "23" => :pc_illusion,
    "24" => :pc_conjuration,
    "25" => :pc_mysticism,
    "26" => :pc_restoration,
    "27" => :pc_alchemy,
    "28" => :pc_unarmored,
    "29" => :pc_security,
    "30" => :pc_sneak,
    "31" => :pc_acrobatics,
    "32" => :pc_light_armor,
    "33" => :pc_short_blade,
    "34" => :pc_marksman,
    "35" => :pc_mercantile,
    "36" => :pc_speechcraft,
    "37" => :pc_hand_to_hand,
    "38" => :pc_gender,
    "39" => :pc_expelled,
    "40" => :pc_common_disease,
    "41" => :pc_blight_disease,
    "42" => :pc_clothing_modifier,
    "43" => :pc_crime_level,
    "44" => :same_gender,
    "45" => :same_race,
    "46" => :same_faction,
    "47" => :faction_rank_diff,
    "48" => :detected,
    "49" => :alarmed,
    "50" => :choice,
    "51" => :pc_intelligence,
    "52" => :pc_willpower,
    "53" => :pc_agility,
    "54" => :pc_speed,
    "55" => :pc_endurance,
    "56" => :pc_personality,
    "57" => :pc_luck,
    "58" => :pc_corprus,
    "59" => :weather,
    "60" => :pc_vampire,
    "61" => :level,
    "62" => :attacked,
    "63" => :talked_to_pc,
    "64" => :pc_health,
    "65" => :creature_target,
    "66" => :friend_hit,
    "67" => :fight,
    "68" => :hello,
    "69" => :alarm,
    "70" => :flee,
    "71" => :should_attack,
    "sX" => :not_local,
    "JX" => :journal,
    "IX" => :item,
    "DX" => :dead,
    "XX" => :not_id,
    "FX" => :not_faction,
    "CX" => :not_class,
    "RX" => :not_race,
    "LX" => :not_cell,
    "fX" => :global
  }

  @operators %{
    "0" => :=,
    "1" => :!=,
    "2" => :>,
    "3" => :>=,
    "4" => :<,
    "5" => :<
  }

  process_basic_string "INAM", :id
  process_basic_string "PNAM", :previous_id
  process_basic_string "NNAM", :next_id
  process_basic_string "NAME", :content
  process_basic_string "BNAM", :script_content
  process_basic_string "ONAM", :actor_id
  process_basic_string "ANAM", :cell_name
  process_basic_string "DNAM", :pc_faction
  process_basic_string "CNAM", :class
  process_basic_string "SNAM", :sound_id
  process_basic_string "RNAM", :race

  def process({"DATA", value}, data) do
    <<type::uint8(), _::char(3), disposition_or_journal_index::uint32(), rank::int8(),
      gender::int8(), pc_rank::int8(), _::binary>> = value

    record_unnested_value(data, %{
      type: Resdayn.Parser.Record.DialogueTopic.by_type(type),
      disposition_or_journal_index: disposition_or_journal_index,
      rank: nil_if_negative(rank),
      gender: gender(gender),
      pc_rank: nil_if_negative(pc_rank)
    })
  end

  def process({"FNAM", "FFFF"}, data) do
    record_value(data, :faction_id, nil)
  end

  def process({"FNAM" = v, value}, data) do
    record_value(data, :faction_id, printable!(__MODULE__, v, value))
  end

  def process({"SCVR", value}, data) do
    <<_index::char(1), type::char(1), function::char(2), operator::char(1), name::binary>> =
      value

    function =
      cond do
        type == "2" -> :global
        type == "3" -> :local
        type == "C" -> :not_local
        true -> Map.fetch(@functions, function)
      end

    record_list(data, :conditions, %{
      function: function,
      operator: Map.fetch!(@operators, operator),
      name: name
    })
  end

  def process({"FLTV", <<value::float32()>>}, data) do
    record_list_of_maps_value(data, :conditions, :value, value)
  end

  def process({"INTV", <<value::int32()>>}, data) do
    record_list_of_maps_value(data, :conditions, :value, value)
  end

  defp gender(-1), do: :none
  defp gender(0), do: :male
  defp gender(1), do: :female
end
