defmodule Resdayn.Parser.Record.DialogueResponse do
  use Resdayn.Parser.Record

  @functions %{
    "00" => :rank_low,
    "01" => :rank_high,
    "02" => :rank_requirement,
    "03" => :reputation,
    "04" => :health_percent,
    "05" => :player_reputation,
    "06" => :player_level,
    "07" => :player_health_percent,
    "08" => :player_magicka,
    "09" => :player_fatigue,
    "10" => :player_strength,
    "11" => :player_block,
    "12" => :player_armorer,
    "13" => :player_medium_armor,
    "14" => :player_heavy_armor,
    "15" => :player_blunt_weapon,
    "16" => :player_long_blade,
    "17" => :player_axe,
    "18" => :player_spear,
    "19" => :player_athletics,
    "20" => :player_enchant,
    "21" => :player_destruction,
    "22" => :player_alteration,
    "23" => :player_illusion,
    "24" => :player_conjuration,
    "25" => :player_mysticism,
    "26" => :player_restoration,
    "27" => :player_alchemy,
    "28" => :player_unarmored,
    "29" => :player_security,
    "30" => :player_sneak,
    "31" => :player_acrobatics,
    "32" => :player_light_armor,
    "33" => :player_short_blade,
    "34" => :player_marksman,
    "35" => :player_mercantile,
    "36" => :player_speechcraft,
    "37" => :player_hand_to_hand,
    "38" => :player_gender,
    "39" => :player_expelled,
    "40" => :player_common_disease,
    "41" => :player_blight_disease,
    "42" => :player_clothing_modifier,
    "43" => :player_crime_level,
    "44" => :same_gender,
    "45" => :same_race,
    "46" => :same_faction,
    "47" => :faction_rank_diff,
    "48" => :detected,
    "49" => :alarmed,
    "50" => :choice,
    "51" => :player_intelligence,
    "52" => :player_willpower,
    "53" => :player_agility,
    "54" => :player_speed,
    "55" => :player_endurance,
    "56" => :player_personality,
    "57" => :player_luck,
    "58" => :player_corprus,
    "59" => :weather,
    "60" => :player_vampire,
    "61" => :level,
    "62" => :attacked,
    "63" => :talked_to_player,
    "64" => :player_health,
    "65" => :creature_target,
    "66" => :friend_hit,
    "67" => :fight,
    "68" => :hello,
    "69" => :alarm,
    "70" => :flee,
    "71" => :should_attack,
    "72" => :werewolf_kill,
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
    "5" => :<=
  }

  process_basic_string "INAM", :id
  process_basic_string "PNAM", :previous_response_id
  process_basic_string "NNAM", :next_response_id
  process_basic_string "NAME", :content
  process_basic_string "BNAM", :script_content
  process_basic_string "ONAM", :actor_id
  process_basic_string "ANAM", :cell_name
  process_basic_string "DNAM", :player_faction_id
  process_basic_string "CNAM", :speaker_class_id
  process_basic_string "SNAM", :sound_filename
  process_basic_string "RNAM", :speaker_race_id

  def process({"DELE", <<0::uint32()>>}, data) do
    Map.put(data, :deleted, true)
  end

  def process({"DATA", value}, data) do
    <<type::uint8(), _::char(3), disposition_or_journal_index::uint32(), rank::int8(),
      gender::int8(), player_rank::int8(), _::binary>> = value

    record_unnested_value(data, %{
      type: Resdayn.Parser.Record.DialogueTopic.by_type(type),
      disposition_or_journal_index: disposition_or_journal_index,
      speaker_faction_rank: nil_if_negative(rank),
      gender: gender(gender),
      player_faction_rank: nil_if_negative(player_rank)
    })
  end

  def process({"FNAM" = v, value}, data) do
    faction_id =
      case printable!(__MODULE__, v, value) do
        "FFFF" -> nil
        printable -> printable
      end

    record_value(data, :speaker_faction_id, faction_id)
  end

  def process({"SCVR", value}, data) do
    <<_index::char(1), type::char(1), function::char(2), operator::char(1), name::binary>> =
      value

    function =
      cond do
        type == "2" -> :global
        type == "3" -> :local
        type == "C" -> :not_local
        true -> Map.get(@functions, function, {:unknown_function, function})
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

  def process({"QSTN", value}, data) do
    record_value(data, :quest_name, value == <<1>>)
  end

  def process({"QSTF", value}, data) do
    record_value(data, :finishes_quest, value == <<1>>)
  end

  def process({"QSTR", value}, data) do
    record_value(data, :restarts_quest, value == <<1>>)
  end

  defp gender(-1), do: nil
  defp gender(0), do: :male
  defp gender(1), do: :female
end
