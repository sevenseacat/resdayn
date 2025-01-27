defmodule Resdayn.Parser.Record.MagicEffect do
  use Resdayn.Parser.Record

  @school_to_skill_id %{
    0 => 11,
    1 => 13,
    2 => 10,
    3 => 12,
    4 => 14,
    5 => 15
  }

  @field_name_mappings %{
    "ITEX" => :icon_filename,
    "PTEX" => :particle_texture_filename,
    "CVFX" => :casting_visual,
    "BVFX" => :bolt_visual,
    "HVFX" => :hit_visual,
    "AVFX" => :area_visual,
    "DESC" => :description,
    "BSND" => :bolt_sound_id,
    "CSND" => :casting_sound_id,
    "HSND" => :hit_sound_id,
    "ASND" => :area_sound_id
  }

  @game_setting_ids %{
    0 => "sEffectWaterBreathing",
    1 => "sEffectSwiftSwim",
    2 => "sEffectWaterWalking",
    3 => "sEffectShield",
    4 => "sEffectFireShield",
    5 => "sEffectLightningShield",
    6 => "sEffectFrostShield",
    7 => "sEffectBurden",
    8 => "sEffectFeather",
    9 => "sEffectJump",
    10 => "sEffectLevitate",
    11 => "sEffectSlowFall",
    12 => "sEffectLock",
    13 => "sEffectOpen",
    14 => "sEffectFireDamage",
    15 => "sEffectShockDamage",
    16 => "sEffectFrostDamage",
    17 => "sEffectDrainAttribute",
    18 => "sEffectDrainHealth",
    19 => "sEffectDrainSpellpoints",
    20 => "sEffectDrainFatigue",
    21 => "sEffectDrainSkill",
    22 => "sEffectDamageAttribute",
    23 => "sEffectDamageHealth",
    24 => "sEffectDamageMagicka",
    25 => "sEffectDamageFatigue",
    26 => "sEffectDamageSkill",
    27 => "sEffectPoison",
    28 => "sEffectWeaknessToFire",
    29 => "sEffectWeaknessToFrost",
    30 => "sEffectWeaknessToShock",
    31 => "sEffectWeaknessToMagicka",
    32 => "sEffectWeaknessToCommonDisease",
    33 => "sEffectWeaknessToBlightDisease",
    34 => "sEffectWeaknessToCorprusDisease",
    35 => "sEffectWeaknessToPoison",
    36 => "sEffectWeaknessToNormalWeapons",
    37 => "sEffectDisintegrateWeapon",
    38 => "sEffectDisintegrateArmor",
    39 => "sEffectInvisibility",
    40 => "sEffectChameleon",
    41 => "sEffectLight",
    42 => "sEffectSanctuary",
    43 => "sEffectNightEye",
    44 => "sEffectCharm",
    45 => "sEffectParalyze",
    46 => "sEffectSilence",
    47 => "sEffectBlind",
    48 => "sEffectSound",
    49 => "sEffectCalmHumanoid",
    50 => "sEffectCalmCreature",
    51 => "sEffectFrenzyHumanoid",
    52 => "sEffectFrenzyCreature",
    53 => "sEffectDemoralizeHumanoid",
    54 => "sEffectDemoralizeCreature",
    55 => "sEffectRallyHumanoid",
    56 => "sEffectRallyCreature",
    57 => "sEffectDispel",
    58 => "sEffectSoultrap",
    59 => "sEffectTelekinesis",
    60 => "sEffectMark",
    61 => "sEffectRecall",
    62 => "sEffectDivineIntervention",
    63 => "sEffectAlmsiviIntervention",
    64 => "sEffectDetectAnimal",
    65 => "sEffectDetectEnchantment",
    66 => "sEffectDetectKey",
    67 => "sEffectSpellAbsorption",
    68 => "sEffectReflect",
    69 => "sEffectCureCommonDisease",
    70 => "sEffectCureBlightDisease",
    71 => "sEffectCureCorprusDisease",
    72 => "sEffectCurePoison",
    73 => "sEffectCureParalyzation",
    74 => "sEffectRestoreAttribute",
    75 => "sEffectRestoreHealth",
    76 => "sEffectRestoreSpellPoints",
    77 => "sEffectRestoreFatigue",
    78 => "sEffectRestoreSkill",
    79 => "sEffectFortifyAttribute",
    80 => "sEffectFortifyHealth",
    81 => "sEffectFortifySpellpoints",
    82 => "sEffectFortifyFatigue",
    83 => "sEffectFortifySkill",
    84 => "sEffectFortifyMagickaMultiplier",
    85 => "sEffectAbsorbAttribute",
    86 => "sEffectAbsorbHealth",
    87 => "sEffectAbsorbSpellPoints",
    88 => "sEffectAbsorbFatigue",
    89 => "sEffectAbsorbSkill",
    90 => "sEffectResistFire",
    91 => "sEffectResistFrost",
    92 => "sEffectResistShock",
    93 => "sEffectResistMagicka",
    94 => "sEffectResistCommonDisease",
    95 => "sEffectResistBlightDisease",
    96 => "sEffectResistCorprusDisease",
    97 => "sEffectResistPoison",
    98 => "sEffectResistNormalWeapons",
    99 => "sEffectResistParalysis",
    100 => "sEffectRemoveCurse",
    101 => "sEffectTurnUndead",
    102 => "sEffectSummonScamp",
    103 => "sEffectSummonClannfear",
    104 => "sEffectSummonDaedroth",
    105 => "sEffectSummonDremora",
    106 => "sEffectSummonAncestralGhost",
    107 => "sEffectSummonSkeletalMinion",
    108 => "sEffectSummonLeastBonewalker",
    109 => "sEffectSummonGreaterBonewalker",
    110 => "sEffectSummonBonelord",
    111 => "sEffectSummonWingedTwilight",
    112 => "sEffectSummonHunger",
    113 => "sEffectSummonGoldensaint",
    114 => "sEffectSummonFlameAtronach",
    115 => "sEffectSummonFrostAtronach",
    116 => "sEffectSummonStormAtronach",
    117 => "sEffectFortifyAttackBonus",
    118 => "sEffectCommandCreatures",
    119 => "sEffectCommandHumanoids",
    120 => "sEffectBoundDagger",
    121 => "sEffectBoundLongsword",
    122 => "sEffectBoundMace",
    123 => "sEffectBoundBattleAxe",
    124 => "sEffectBoundSpear",
    125 => "sEffectBoundLongbow",
    126 => "sEffectExtraSpell",
    127 => "sEffectBoundCuirass",
    128 => "sEffectBoundHelm",
    129 => "sEffectBoundBoots",
    130 => "sEffectBoundShield",
    131 => "sEffectBoundGloves",
    132 => "sEffectCorpus",
    133 => "sEffectVampirism",
    134 => "sEffectSummonCenturionSphere",
    135 => "sEffectSunDamage",
    136 => "sEffectStuntedMagicka",
    137 => "sEffectSummonFabricant",
    138 => "sEffectSummonCreature01",
    139 => "sEffectSummonCreature02",
    140 => "sEffectSummonCreature03",
    141 => "sEffectSummonCreature04",
    142 => "sEffectSummonCreature05"
  }

  def process({"INDX", <<value::uint32()>>}, data) do
    record_unnested_value(
      data,
      %{
        id: value,
        game_setting_id: Map.fetch!(@game_setting_ids, value)
      }
    )
  end

  def process({"MEDT", value}, data) do
    <<school::uint32(), base_cost::float32(), flags::uint32(), red::uint32(), green::uint32(),
      blue::uint32(), speed::float32(), size::float32(), size_cap::float32()>> = value

    record_unnested_value(data, %{
      skill_id: school_to_skill_id(school),
      base_cost: float(base_cost),
      color: color({red, green, blue}),
      speed: float(speed),
      size: float(size),
      size_cap: float(size_cap),
      flags:
        bitmask(flags,
          allows_spellmaking: 0x00200,
          allows_enchanting: 0x00400,
          negative_light: 0x00800
        )
    })
  end

  def process({key, value}, data) when is_map_key(@field_name_mappings, key) do
    record_value(data, Map.fetch!(@field_name_mappings, key), printable!(__MODULE__, key, value))
  end

  defp school_to_skill_id(school), do: Map.fetch!(@school_to_skill_id, school)
end
