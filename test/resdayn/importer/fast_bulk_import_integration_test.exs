defmodule Resdayn.Importer.FastBulkImportIntegrationTest do
  @moduledoc """
  Integration tests for FastBulkImport.

  These tests run the actual Resdayn.Importer.Runner to import Morrowind.esm,
  then verify data integrity for resources that have been converted to FastBulkImport.
  """
  use Resdayn.DataCase, async: true

  alias Resdayn.Importer.FastBulkImport

  # Resources under test
  alias Resdayn.Codex.Mechanics.{
    GameSetting,
    GlobalVariable,
    Attribute,
    MagicEffect,
    Script,
    Spell,
    Enchantment
  }

  alias Resdayn.Codex.Characters.{Skill, Class, Birthsign, Race, BodyPart, Faction}
  alias Resdayn.Codex.Assets.{Sound, StaticObject, Light, SoundGenerator}

  alias Resdayn.Codex.Items.{
    Book,
    Weapon,
    MiscellaneousItem,
    Armor,
    Clothing,
    Ingredient,
    Potion,
    Tool,
    ItemLevelledList
  }

  alias Resdayn.Codex.World.{
    Activator,
    Door,
    Container,
    Region,
    Creature,
    CreatureLevelledList,
    NPC,
    ReferencableObject
  }

  @moduletag :integration

  setup_all do
    truncate_all_tables()

    Resdayn.Importer.Runner.run("Morrowind.esm")

    # Parse records once for re-import tests.
    # We use persistent_term instead of returning from setup_all because ExUnit
    # copies the setup_all return value to each test process. With ~48k parsed
    # records, this copying added ~27 seconds to the test suite.
    # persistent_term stores data in shared memory that all processes can read
    # without copying.
    path = Path.join([:code.priv_dir(:resdayn), "data", "Morrowind.esm"])
    records = Resdayn.Parser.read(path) |> Enum.to_list()
    :persistent_term.put(:test_morrowind_records, records)

    on_exit(fn -> :persistent_term.erase(:test_morrowind_records) end)

    :ok
  end

  defp get_morrowind_records do
    :persistent_term.get(:test_morrowind_records)
  end

  # =============================================================================
  # Phase 1a: Simple Resources (no Referencable extension)
  # =============================================================================

  describe "GameSetting" do
    test "imports correct count" do
      count = Ash.count!(GameSetting)
      assert count == 1449, "Expected 1449 game settings, got #{count}"
    end

    test "imports string values correctly" do
      setting = Ash.get!(GameSetting, "sMonthMorningstar")
      assert setting.value == %Ash.Union{type: :string, value: "Morning Star"}
      assert setting.source_file_ids == ["Morrowind.esm"]
    end

    test "imports integer values correctly" do
      setting = Ash.get!(GameSetting, "iMaxActivateDist")
      assert setting.value == %Ash.Union{type: :integer, value: 192}
    end

    test "imports float values correctly" do
      setting = Ash.get!(GameSetting, "fMagicItemRechargePerSecond")
      assert setting.value == %Ash.Union{type: :float, value: 0.05}
    end
  end

  describe "Attribute" do
    test "imports all 8 attributes" do
      count = Ash.count!(Attribute)
      assert count == 8, "Expected 8 attributes, got #{count}"
    end

    test "imports attribute names correctly" do
      expected = [
        {0, "Strength"},
        {1, "Intelligence"},
        {2, "Willpower"},
        {3, "Agility"},
        {4, "Speed"},
        {5, "Endurance"},
        {6, "Personality"},
        {7, "Luck"}
      ]

      actual = Ash.read!(Attribute)

      for {id, name} <- expected do
        attr = Enum.find(actual, &(&1.id == id))
        assert attr != nil
        assert attr.name == name
        assert attr.source_file_ids == ["Morrowind.esm"]
      end
    end
  end

  describe "GlobalVariable" do
    test "imports correct count" do
      count = Ash.count!(GlobalVariable)
      assert count == 73, "Expected 73 global variables, got #{count}"
    end

    test "imports integer values correctly" do
      setting = Ash.get!(GlobalVariable, "NPCVoiceDistance")
      assert setting.value == %Ash.Union{type: :integer, value: 750}
      assert setting.source_file_ids == ["Morrowind.esm"]
    end

    test "imports float values correctly" do
      setting = Ash.get!(GlobalVariable, "GameHour")
      assert setting.value == %Ash.Union{type: :float, value: 9.0}
    end
  end

  describe "Skill" do
    test "imports all 27 skills" do
      count = Ash.count!(Skill)
      assert count == 27, "Expected 27 skills, got #{count}"
    end

    test "imports skill data correctly" do
      # Block skill
      skill = Ash.get!(Skill, 0)
      assert skill.name == "Block"
      assert skill.specialization == :combat
      # Agility
      assert skill.attribute_id == 3
      assert length(skill.uses) == 4
      assert skill.source_file_ids == ["Morrowind.esm"]
    end
  end

  describe "Script" do
    test "imports correct count" do
      count = Ash.count!(Script)
      assert count == 632, "Expected 632 scripts, got #{count}"
    end

    test "imports script data correctly" do
      script = Ash.get!(Script, "ajiraScript")
      assert String.starts_with?(script.text, "Begin ajiraScript\n\nshort doOnce")
      assert script.local_variables == ["doOnce"]
      assert script.start_script == false
      assert script.source_file_ids == ["Morrowind.esm"]
    end
  end

  describe "MagicEffect" do
    test "imports all 137 magic effects" do
      count = Ash.count!(MagicEffect)
      assert count == 137, "Expected 137 magic effects, got #{count}"
    end

    test "imports magic effect data correctly" do
      effect = Ash.get!(MagicEffect, 14)

      assert effect.game_setting_id == "sEffectFireDamage"
      assert effect.base_cost == 5
      assert effect.icon_filename == "s\\Tx_S_fire_damage.tga"
      assert effect.color == "#FD8842"
      assert effect.source_file_ids == ["Morrowind.esm"]

      assert String.starts_with?(
               effect.description,
               "This spell effect produces a manifestation of elemental fire."
             )
    end
  end

  describe "Class" do
    test "imports correct count" do
      count = Ash.count!(Class)
      assert count == 77, "Expected 77 classes, got #{count}"
    end

    test "imports class data correctly" do
      class = Ash.get!(Class, "Warrior")
      assert class.name == "Warrior"
      assert class.specialization == :combat
      assert class.playable == true
      assert class.attribute1_id == 0
      assert class.attribute2_id == 5
      assert class.source_file_ids == ["Morrowind.esm"]

      assert String.starts_with?(
               class.description,
               "Warriors are the professional men-at-arms"
             )
    end

    test "imports services_offered correctly" do
      # Find a class with services
      classes = Ash.read!(Class)
      service_class = Enum.find(classes, fn c -> length(c.services_offered) > 0 end)

      if service_class do
        assert is_list(service_class.services_offered)
      end
    end
  end

  describe "ClassSkill" do
    test "imports correct count" do
      count = Ash.count!(Resdayn.Codex.Characters.Class.Skill)
      # 77 classes * 10 skills each (5 major + 5 minor) = 770
      assert count == 770, "Expected 770 class skills, got #{count}"
    end

    test "imports class skill data correctly" do
      require Ash.Query

      skills =
        Resdayn.Codex.Characters.Class.Skill
        |> Ash.Query.filter(class_id == "Warrior")
        |> Ash.read!()

      assert length(skills) == 10

      major_skills = Enum.filter(skills, fn s -> s.category == :major end)
      minor_skills = Enum.filter(skills, fn s -> s.category == :minor end)

      assert length(major_skills) == 5
      assert length(minor_skills) == 5
      assert Enum.all?(skills, fn s -> s.source_file_ids == ["Morrowind.esm"] end)
    end
  end

  describe "Birthsign" do
    test "imports correct count" do
      count = Ash.count!(Birthsign)
      assert count == 13, "Expected 13 birthsigns, got #{count}"
    end

    test "imports birthsign data correctly" do
      birthsign = Ash.get!(Birthsign, "Fay")
      assert birthsign.name == "The Mage"
      assert birthsign.description == "Constellation of The Mage with a Prime Aspect of Masser."
      assert birthsign.artwork_filename == "Birthsigns\\Tx_birth_mage.tga"
      assert birthsign.source_file_ids == ["Morrowind.esm"]
    end

    test "imports spells embedded array correctly" do
      birthsign = Ash.get!(Birthsign, "Fay")
      assert is_list(birthsign.spells)
      assert length(birthsign.spells) == 1
      assert hd(birthsign.spells).spell_id == "fay ability"
    end
  end

  # =============================================================================
  # Phase 1a continued: Resources with embedded types
  # =============================================================================

  describe "Spell" do
    test "imports correct count" do
      count = Ash.count!(Spell)
      # 990 in file, minus 1 duplicate that gets filtered
      assert count == 989, "Expected 989 spells, got #{count}"
    end

    test "imports spell data correctly" do
      spell = Ash.get!(Spell, "fireball")
      assert spell.name == "Fireball"
      assert spell.type == :spell
      assert spell.cost > 0
      assert spell.source_file_ids == ["Morrowind.esm"]
    end

    test "imports spell effects embedded array correctly" do
      spell = Ash.get!(Spell, "fireball")
      assert is_list(spell.effects)
      assert length(spell.effects) > 0

      effect = hd(spell.effects)
      assert Map.has_key?(effect, :magic_effect_id)
      assert Map.has_key?(effect, :range)
      assert Map.has_key?(effect, :duration)
      assert Map.has_key?(effect, :magnitude)
    end

    test "imports spell_flags correctly" do
      spells = Ash.read!(Spell)
      autocalc_spell = Enum.find(spells, fn s -> :autocalc in s.spell_flags end)
      assert autocalc_spell != nil
    end
  end

  describe "Enchantment" do
    test "imports correct count" do
      count = Ash.count!(Enchantment)
      assert count == 708, "Expected 708 enchantments, got #{count}"
    end

    test "imports enchantment data correctly" do
      enchantment = Ash.get!(Enchantment, "bonebiter")
      assert enchantment.type == :cast_on_strike
      assert enchantment.cost >= 0
      assert enchantment.charge >= 0
      assert enchantment.source_file_ids == ["Morrowind.esm"]
    end

    test "imports enchantment effects embedded array correctly" do
      enchantment = Ash.get!(Enchantment, "bonebiter")
      assert is_list(enchantment.effects)
      assert length(enchantment.effects) > 0

      effect = hd(enchantment.effects)
      assert Map.has_key?(effect, :magic_effect_id)
      assert Map.has_key?(effect, :range)
    end
  end

  # =============================================================================
  # Phase 1b: Referencable Resources
  # =============================================================================

  describe "StaticObject (Referencable)" do
    test "imports correct count" do
      count = Ash.count!(StaticObject)
      assert count == 2788, "Expected 2788 static objects, got #{count}"
    end

    test "imports static object data correctly" do
      static = Ash.get!(StaticObject, "DoorMarker")
      assert static.nif_model_filename == "Marker_Arrow.nif"
      assert static.source_file_ids == ["Morrowind.esm"]
    end

    test "creates corresponding ReferencableObject" do
      ref_obj = Ash.get!(ReferencableObject, "DoorMarker")
      assert ref_obj.type == :static_object
    end

    test "imports all static objects with ReferencableObject entries" do
      static_count = Ash.count!(StaticObject)
      ref_count = Ash.count!(ReferencableObject, query: [filter: [type: :static_object]])

      assert static_count == ref_count,
             "StaticObject count (#{static_count}) should match ReferencableObject count (#{ref_count})"
    end
  end

  describe "Activator (Referencable)" do
    test "imports correct count" do
      count = Ash.count!(Activator)
      assert count == 697, "Expected 697 activators, got #{count}"
    end

    test "imports activator data correctly" do
      activator = Ash.get!(Activator, "tavern sign")
      assert activator.name == "Imperial Tavern"
      assert activator.nif_model_filename == "x\\Furn_sign_inn_01.NIF"
      assert activator.script_id == "SignRotate"
      assert activator.source_file_ids == ["Morrowind.esm"]
    end

    test "creates corresponding ReferencableObject" do
      ref_obj = Ash.get!(ReferencableObject, "tavern sign")
      assert ref_obj.type == :activator
    end

    test "imports all activators with ReferencableObject entries" do
      activator_count = Ash.count!(Activator)
      ref_count = Ash.count!(ReferencableObject, query: [filter: [type: :activator]])

      assert activator_count == ref_count,
             "Activator count (#{activator_count}) should match ReferencableObject count (#{ref_count})"
    end
  end

  describe "Light (Referencable)" do
    test "imports correct count" do
      count = Ash.count!(Light)
      assert count == 574, "Expected 574 lights, got #{count}"
    end

    test "imports light data correctly" do
      light = Ash.get!(Light, "light_torch_01")
      assert light.nif_model_filename == "l\\Light_torch_01.NIF"
      assert light.radius == 256
      assert light.color == "#F58C28"
      assert light.time == -1
      assert light.value == 0
      assert light.weight == 0.0
      assert light.sound_id == "Fire 40"
      assert light.source_file_ids == ["Morrowind.esm"]
    end

    test "imports light_flags correctly" do
      light = Ash.get!(Light, "light_torch_01")
      assert is_list(light.light_flags)
      assert :dynamic in light.light_flags
      assert :fire in light.light_flags
      assert :flicker_slow in light.light_flags
    end

    test "creates corresponding ReferencableObject" do
      ref_obj = Ash.get!(ReferencableObject, "light_torch_01")
      assert ref_obj.type == :light
    end

    test "imports all lights with ReferencableObject entries" do
      light_count = Ash.count!(Light)
      ref_count = Ash.count!(ReferencableObject, query: [filter: [type: :light]])

      assert light_count == ref_count,
             "Light count (#{light_count}) should match ReferencableObject count (#{ref_count})"
    end
  end

  describe "Door (Referencable)" do
    test "imports correct count" do
      count = Ash.count!(Door)
      assert count == 140, "Expected 140 doors, got #{count}"
    end

    test "imports door data correctly" do
      door = Ash.get!(Door, "PrisonMarker")
      assert door.nif_model_filename == "Marker_Prison.nif"
      assert door.source_file_ids == ["Morrowind.esm"]
    end

    test "creates corresponding ReferencableObject" do
      ref_obj = Ash.get!(ReferencableObject, "PrisonMarker")
      assert ref_obj.type == :door
    end

    test "imports all doors with ReferencableObject entries" do
      door_count = Ash.count!(Door)
      ref_count = Ash.count!(ReferencableObject, query: [filter: [type: :door]])

      assert door_count == ref_count,
             "Door count (#{door_count}) should match ReferencableObject count (#{ref_count})"
    end
  end

  describe "Sound (Referencable)" do
    test "imports correct count" do
      count = Ash.count!(Sound)
      assert count == 430, "Expected 430 sounds, got #{count}"
    end

    test "imports sound data correctly" do
      sound = Ash.get!(Sound, "Fire")
      assert sound.filename == "Fx\\envrn\\fire.wav"
      assert sound.volume == 204
      assert sound.range == %{min: 2, max: 15}
      assert sound.source_file_ids == ["Morrowind.esm"]
    end

    test "creates corresponding ReferencableObject" do
      # Sound should have a corresponding entry in referencable_objects
      ref_obj = Ash.get!(ReferencableObject, "Fire")
      assert ref_obj.type == :sound
    end

    test "imports all sounds with ReferencableObject entries" do
      sound_count = Ash.count!(Sound)
      ref_count = Ash.count!(ReferencableObject, query: [filter: [type: :sound]])

      assert sound_count == ref_count,
             "Sound count (#{sound_count}) should match ReferencableObject count (#{ref_count})"
    end
  end

  describe "Book (Referencable)" do
    test "imports correct count" do
      count = Ash.count!(Book)
      assert count == 574, "Expected 574 books, got #{count}"
    end

    test "imports book data correctly" do
      book = Ash.get!(Book, "BookSkill_Enchant1")
      assert book.name == "Feyfolken I"
      assert book.value == 300
      assert book.weight == Decimal.new("4.0")
      assert book.skill_id == 9
      assert book.scroll == false
      assert book.source_file_ids == ["Morrowind.esm"]
    end

    test "creates corresponding ReferencableObject" do
      ref_obj = Ash.get!(ReferencableObject, "BookSkill_Enchant1")
      assert ref_obj.type == :book
    end

    test "imports all books with ReferencableObject entries" do
      book_count = Ash.count!(Book)
      ref_count = Ash.count!(ReferencableObject, query: [filter: [type: :book]])

      assert book_count == ref_count,
             "Book count (#{book_count}) should match ReferencableObject count (#{ref_count})"
    end
  end

  describe "Weapon (Referencable)" do
    test "imports correct count" do
      count = Ash.count!(Weapon)
      assert count == 485, "Expected 485 weapons, got #{count}"
    end

    test "imports weapon data correctly" do
      weapon = Ash.get!(Weapon, "iron dagger")
      assert weapon.name == "Iron Dagger"
      assert weapon.type == :short_blade
      assert weapon.value > 0
      assert weapon.source_file_ids == ["Morrowind.esm"]
    end

    test "imports weapon magnitude ranges correctly" do
      weapon = Ash.get!(Weapon, "iron dagger")
      assert Map.has_key?(weapon.chop_magnitude, :min)
      assert Map.has_key?(weapon.chop_magnitude, :max)
      assert Map.has_key?(weapon.slash_magnitude, :min)
      assert Map.has_key?(weapon.thrust_magnitude, :min)
    end

    test "creates corresponding ReferencableObject" do
      ref_obj = Ash.get!(ReferencableObject, "iron dagger")
      assert ref_obj.type == :weapon
    end

    test "imports all weapons with ReferencableObject entries" do
      weapon_count = Ash.count!(Weapon)
      ref_count = Ash.count!(ReferencableObject, query: [filter: [type: :weapon]])

      assert weapon_count == ref_count,
             "Weapon count (#{weapon_count}) should match ReferencableObject count (#{ref_count})"
    end
  end

  describe "MiscellaneousItem (Referencable)" do
    test "imports correct count" do
      count = Ash.count!(MiscellaneousItem)
      assert count == 536, "Expected 536 miscellaneous items, got #{count}"
    end

    test "imports miscellaneous item data correctly" do
      item = Ash.get!(MiscellaneousItem, "Gold_001")
      assert item.name == "Gold"
      assert item.value == 1
      assert item.weight == Decimal.new("0.0")
      assert item.source_file_ids == ["Morrowind.esm"]
    end

    test "creates corresponding ReferencableObject" do
      ref_obj = Ash.get!(ReferencableObject, "Gold_001")
      assert ref_obj.type == :miscellaneous_item
    end

    test "imports all miscellaneous items with ReferencableObject entries" do
      misc_count = Ash.count!(MiscellaneousItem)
      ref_count = Ash.count!(ReferencableObject, query: [filter: [type: :miscellaneous_item]])

      assert misc_count == ref_count,
             "MiscellaneousItem count (#{misc_count}) should match ReferencableObject count (#{ref_count})"
    end
  end

  describe "Armor (Referencable)" do
    test "imports correct count" do
      count = Ash.count!(Armor)
      assert count == 280, "Expected 280 armor, got #{count}"
    end

    test "imports armor data correctly" do
      armor = Ash.get!(Armor, "chitin cuirass")
      assert armor.name == "Chitin Cuirass"
      assert armor.type == :cuirass
      assert armor.value == 45
      assert armor.armor_rating == 10
      assert armor.health == 300
      assert armor.source_file_ids == ["Morrowind.esm"]
    end

    test "imports armor class correctly" do
      armor = Ash.get!(Armor, "chitin cuirass")
      assert armor.class in [:light, :medium, :heavy]
    end

    test "creates corresponding ReferencableObject" do
      ref_obj = Ash.get!(ReferencableObject, "chitin cuirass")
      assert ref_obj.type == :armor
    end

    test "imports all armor with ReferencableObject entries" do
      armor_count = Ash.count!(Armor)
      ref_count = Ash.count!(ReferencableObject, query: [filter: [type: :armor]])

      assert armor_count == ref_count,
             "Armor count (#{armor_count}) should match ReferencableObject count (#{ref_count})"
    end
  end

  describe "Clothing (Referencable)" do
    test "imports correct count" do
      count = Ash.count!(Clothing)
      assert count == 510, "Expected 510 clothing, got #{count}"
    end

    test "imports clothing data correctly" do
      clothing = Ash.get!(Clothing, "templar belt")
      assert clothing.name == "Imperial Templar Belt"
      assert clothing.type == :belt
      assert clothing.value == 4
      assert clothing.source_file_ids == ["Morrowind.esm"]
    end

    test "creates corresponding ReferencableObject" do
      ref_obj = Ash.get!(ReferencableObject, "templar belt")
      assert ref_obj.type == :clothing
    end

    test "imports all clothing with ReferencableObject entries" do
      clothing_count = Ash.count!(Clothing)
      ref_count = Ash.count!(ReferencableObject, query: [filter: [type: :clothing]])

      assert clothing_count == ref_count,
             "Clothing count (#{clothing_count}) should match ReferencableObject count (#{ref_count})"
    end
  end

  describe "Ingredient (Referencable)" do
    test "imports correct count" do
      count = Ash.count!(Ingredient)
      assert count == 95, "Expected 95 ingredients, got #{count}"
    end

    test "imports ingredient data correctly" do
      ingredient = Ash.get!(Ingredient, "ingred_dreugh_wax_01")
      assert ingredient.name == "Dreugh Wax"
      assert ingredient.value == 100
      assert ingredient.source_file_ids == ["Morrowind.esm"]
    end

    test "imports ingredient effects embedded array correctly" do
      ingredient = Ash.get!(Ingredient, "ingred_dreugh_wax_01")
      assert is_list(ingredient.effects)
      assert length(ingredient.effects) == 4

      effect = hd(ingredient.effects)
      assert Map.has_key?(effect, :magic_effect_id)
    end

    test "creates corresponding ReferencableObject" do
      ref_obj = Ash.get!(ReferencableObject, "ingred_dreugh_wax_01")
      assert ref_obj.type == :ingredient
    end

    test "imports all ingredients with ReferencableObject entries" do
      ingredient_count = Ash.count!(Ingredient)
      ref_count = Ash.count!(ReferencableObject, query: [filter: [type: :ingredient]])

      assert ingredient_count == ref_count,
             "Ingredient count (#{ingredient_count}) should match ReferencableObject count (#{ref_count})"
    end
  end

  describe "Potion (Referencable)" do
    test "imports correct count" do
      count = Ash.count!(Potion)
      assert count == 258, "Expected 258 potions, got #{count}"
    end

    test "imports potion data correctly" do
      potion = Ash.get!(Potion, "potion_skooma_01")
      assert potion.name == "Skooma"
      assert potion.value == 500
      assert potion.source_file_ids == ["Morrowind.esm"]
    end

    test "imports potion effects embedded array correctly" do
      potion = Ash.get!(Potion, "potion_skooma_01")
      assert is_list(potion.effects)
      assert length(potion.effects) == 4

      effect = hd(potion.effects)
      assert Map.has_key?(effect, :magic_effect_id)
      assert Map.has_key?(effect, :magnitude)
    end

    test "creates corresponding ReferencableObject" do
      ref_obj = Ash.get!(ReferencableObject, "potion_skooma_01")
      assert ref_obj.type == :potion
    end

    test "imports all potions with ReferencableObject entries" do
      potion_count = Ash.count!(Potion)
      ref_count = Ash.count!(ReferencableObject, query: [filter: [type: :potion]])

      assert potion_count == ref_count,
             "Potion count (#{potion_count}) should match ReferencableObject count (#{ref_count})"
    end
  end

  describe "Tool (Referencable)" do
    test "imports correct count" do
      count = Ash.count!(Tool)
      # 6 repair items + 6 lockpicks + 6 probes = 18 total
      assert count == 18, "Expected 18 tools, got #{count}"
    end

    test "imports tool data correctly" do
      tools = Ash.read!(Tool)
      probe = Enum.find(tools, fn t -> t.type == :probe end)

      assert probe != nil
      assert probe.name != nil
      assert probe.source_file_ids == ["Morrowind.esm"]
    end

    test "creates corresponding ReferencableObject entries" do
      tool_count = Ash.count!(Tool)
      ref_count = Ash.count!(ReferencableObject, query: [filter: [type: :tool]])

      assert tool_count == ref_count,
             "Tool count (#{tool_count}) should match ReferencableObject count (#{ref_count})"
    end
  end

  describe "AlchemyApparatus (Referencable)" do
    test "imports correct count" do
      count = Ash.count!(Resdayn.Codex.Items.AlchemyApparatus)
      assert count == 22, "Expected 22 alchemy apparatus, got #{count}"
    end

    test "imports alchemy apparatus data correctly" do
      apparatus = Ash.get!(Resdayn.Codex.Items.AlchemyApparatus, "apparatus_a_mortar_01")

      assert apparatus.name == "Apprentice's Mortar and Pestle"
      assert apparatus.type == :mortar_and_pestle
      assert apparatus.quality == 0.5
      assert apparatus.source_file_ids == ["Morrowind.esm"]
    end

    test "creates corresponding ReferencableObject" do
      apparatus_count = Ash.count!(Resdayn.Codex.Items.AlchemyApparatus)
      ref_count = Ash.count!(ReferencableObject, query: [filter: [type: :alchemy_apparatus]])

      assert apparatus_count == ref_count,
             "AlchemyApparatus count (#{apparatus_count}) should match ReferencableObject count (#{ref_count})"
    end
  end

  describe "Race" do
    test "imports correct count" do
      count = Ash.count!(Race)
      assert count == 10, "Expected 10 races, got #{count}"
    end

    test "imports race data correctly" do
      race = Ash.get!(Race, "Redguard")
      assert race.name == "Redguard"
      assert race.playable == true
      assert race.beast == false
      assert race.source_file_ids == ["Morrowind.esm"]
    end

    test "imports male_stats embedded type correctly" do
      race = Ash.get!(Race, "Redguard")
      assert race.male_stats != nil
      assert race.male_stats.height == 1.02
      assert race.male_stats.weight == 1.1
      assert is_list(race.male_stats.starting_attributes)
    end

    test "imports female_stats embedded type correctly" do
      race = Ash.get!(Race, "Redguard")
      assert race.female_stats != nil
      assert race.female_stats.height == 1.0
      assert race.female_stats.weight == 1.0
    end

    test "imports special_spells embedded array correctly" do
      race = Ash.get!(Race, "Redguard")
      assert is_list(race.special_spells)
      assert length(race.special_spells) == 3
    end
  end

  describe "BodyPart" do
    test "imports correct count" do
      count = Ash.count!(BodyPart)
      assert count == 1125, "Expected 1125 body parts, got #{count}"
    end

    test "imports body part data correctly" do
      parts = Ash.read!(BodyPart)
      part = Enum.find(parts, fn p -> p.race_id == "Breton" and p.type == :hair end)

      assert part != nil
      assert part.equipment_type == :skin
      assert part.source_file_ids == ["Morrowind.esm"]
    end
  end

  describe "Faction" do
    test "imports correct count" do
      count = Ash.count!(Faction)
      assert count == 22, "Expected 22 factions, got #{count}"
    end

    test "imports faction data correctly" do
      faction = Ash.get!(Faction, "Redoran")
      assert faction.name == "Great House Redoran"
      assert faction.hidden == false
      assert faction.attribute1_id == 5
      assert faction.attribute2_id == 0
      assert faction.source_file_ids == ["Morrowind.esm"]
    end

    test "imports faction ranks embedded array correctly" do
      faction = Ash.get!(Faction, "Redoran")
      assert is_list(faction.ranks)
      assert length(faction.ranks) == 10

      first_rank = hd(faction.ranks)
      assert first_rank.name == "Hireling"
    end
  end

  describe "SoundGenerator (Referencable)" do
    test "imports correct count" do
      count = Ash.count!(SoundGenerator)
      assert count == 168, "Expected 168 sound generators, got #{count}"
    end

    test "imports sound generator data correctly" do
      sound_gen = Ash.get!(SoundGenerator, "DEFAULT0001")
      assert sound_gen.sound_id == "FootBareRight"
      assert sound_gen.sound_type == :right_foot
      assert sound_gen.source_file_ids == ["Morrowind.esm"]
    end

    test "creates corresponding ReferencableObject" do
      ref_obj = Ash.get!(ReferencableObject, "DEFAULT0001")
      assert ref_obj.type == :sound_generator
    end

    test "imports all sound generators with ReferencableObject entries" do
      sound_gen_count = Ash.count!(SoundGenerator)
      ref_count = Ash.count!(ReferencableObject, query: [filter: [type: :sound_generator]])

      assert sound_gen_count == ref_count,
             "SoundGenerator count (#{sound_gen_count}) should match ReferencableObject count (#{ref_count})"
    end
  end

  describe "Container (Referencable)" do
    test "imports correct count" do
      count = Ash.count!(Container)
      assert count == 890, "Expected 890 containers, got #{count}"
    end

    test "imports container data correctly" do
      container = Ash.get!(Container, "LootBag")
      assert container.name == "Overflow Loot Bag"
      assert container.nif_model_filename == "o\\LootBag.NIF"
      assert container.capacity == 0.0
      assert container.source_file_ids == ["Morrowind.esm"]
    end

    test "creates corresponding ReferencableObject" do
      ref_obj = Ash.get!(ReferencableObject, "LootBag")
      assert ref_obj.type == :container
    end

    test "imports all containers with ReferencableObject entries" do
      container_count = Ash.count!(Container)
      ref_count = Ash.count!(ReferencableObject, query: [filter: [type: :container]])

      assert container_count == ref_count,
             "Container count (#{container_count}) should match ReferencableObject count (#{ref_count})"
    end
  end

  describe "Region" do
    test "imports correct count" do
      count = Ash.count!(Region)
      assert count == 9, "Expected 9 regions, got #{count}"
    end

    test "imports region data correctly" do
      region = Ash.get!(Region, "Bitter Coast Region")
      assert region.name == "Bitter Coast Region"
      assert region.map_color == "#2227FF"
      assert region.disturb_sleep_creature_id == "ex_bittercoast_sleep"
      assert region.source_file_ids == ["Morrowind.esm"]
    end

    test "imports weather embedded type correctly" do
      region = Ash.get!(Region, "Bitter Coast Region")
      assert region.weather != nil
      assert region.weather.clear == 10
      assert region.weather.cloudy == 60
    end

    test "imports sounds embedded array correctly" do
      region = Ash.get!(Region, "Bitter Coast Region")
      assert is_list(region.sounds)
      assert length(region.sounds) > 0

      sound = hd(region.sounds)
      assert Map.has_key?(sound, :sound_id)
      assert Map.has_key?(sound, :chance)
    end
  end

  describe "ItemLevelledList (Referencable)" do
    test "imports correct count" do
      count = Ash.count!(ItemLevelledList)
      assert count == 227, "Expected 227 item levelled lists, got #{count}"
    end

    test "imports item levelled list data correctly" do
      list = Ash.get!(ItemLevelledList, "random_pos")
      assert list.chance_none == 5
      assert list.for_each_item == true
      assert list.source_file_ids == ["Morrowind.esm"]
    end

    test "imports items embedded array correctly" do
      list = Ash.get!(ItemLevelledList, "random_pos")
      assert is_list(list.items)
      assert length(list.items) > 0

      item = hd(list.items)
      assert Map.has_key?(item, :item_ref_id)
      assert Map.has_key?(item, :player_level)
    end

    test "creates corresponding ReferencableObject" do
      ref_obj = Ash.get!(ReferencableObject, "random_pos")
      assert ref_obj.type == :item_levelled_list
    end

    test "imports all item levelled lists with ReferencableObject entries" do
      list_count = Ash.count!(ItemLevelledList)
      ref_count = Ash.count!(ReferencableObject, query: [filter: [type: :item_levelled_list]])

      assert list_count == ref_count,
             "ItemLevelledList count (#{list_count}) should match ReferencableObject count (#{ref_count})"
    end
  end

  describe "CreatureLevelledList (Referencable)" do
    test "imports correct count" do
      count = Ash.count!(CreatureLevelledList)
      assert count == 116, "Expected 116 creature levelled lists, got #{count}"
    end

    test "imports creature levelled list data correctly" do
      list = Ash.get!(CreatureLevelledList, "l_vamp_cattle")
      assert list.chance_none == 0
      assert list.from_all_lower_levels == true
      assert list.source_file_ids == ["Morrowind.esm"]
    end

    test "imports creatures embedded array correctly" do
      list = Ash.get!(CreatureLevelledList, "l_vamp_cattle")
      assert is_list(list.creatures)
      assert length(list.creatures) == 4

      creature = hd(list.creatures)
      assert Map.has_key?(creature, :creature_id)
      assert Map.has_key?(creature, :player_level)
    end

    test "creates corresponding ReferencableObject" do
      ref_obj = Ash.get!(ReferencableObject, "l_vamp_cattle")
      assert ref_obj.type == :creature_levelled_list
    end

    test "imports all creature levelled lists with ReferencableObject entries" do
      list_count = Ash.count!(CreatureLevelledList)
      ref_count = Ash.count!(ReferencableObject, query: [filter: [type: :creature_levelled_list]])

      assert list_count == ref_count,
             "CreatureLevelledList count (#{list_count}) should match ReferencableObject count (#{ref_count})"
    end
  end

  describe "Creature (Referencable)" do
    test "imports correct count" do
      count = Ash.count!(Creature)
      assert count == 260, "Expected 260 creatures, got #{count}"
    end

    test "imports creature data correctly" do
      creatures = Ash.read!(Creature)
      creature = Enum.find(creatures, fn c -> c.name == "Rat" end)

      assert creature != nil
      assert creature.type in [:creature, :daedra, :undead, :humanoid]
      assert creature.source_file_ids == ["Morrowind.esm"]
    end

    test "imports creature attributes embedded array correctly" do
      creatures = Ash.read!(Creature)
      creature = Enum.find(creatures, fn c -> length(c.attributes) > 0 end)

      assert creature != nil
      assert is_list(creature.attributes)

      attr = hd(creature.attributes)
      assert Map.has_key?(attr, :attribute_id)
      assert Map.has_key?(attr, :value)
    end

    test "creates corresponding ReferencableObject" do
      creatures = Ash.read!(Creature)
      creature = hd(creatures)

      ref_obj = Ash.get!(ReferencableObject, creature.id)
      assert ref_obj.type == :creature
    end

    test "imports all creatures with ReferencableObject entries" do
      creature_count = Ash.count!(Creature)
      ref_count = Ash.count!(ReferencableObject, query: [filter: [type: :creature]])

      assert creature_count == ref_count,
             "Creature count (#{creature_count}) should match ReferencableObject count (#{ref_count})"
    end
  end

  describe "NPC (Referencable)" do
    test "imports correct count" do
      count = Ash.count!(NPC)
      # 2675 total minus 1 for "player" which is filtered out
      assert count == 2674, "Expected 2674 NPCs, got #{count}"
    end

    test "imports npc data correctly" do
      npc = Ash.get!(NPC, "todd")
      assert npc.name == "Todd's Super Tester Guy"
      assert npc.level == 35
      assert npc.race_id == "Dark Elf"
      assert npc.class_id == "Guard"
      assert npc.faction_id == "Blades"
      assert npc.gold == 10000
      assert npc.source_file_ids == ["Morrowind.esm"]
    end

    test "imports npc attributes embedded array correctly" do
      npc = Ash.get!(NPC, "todd")
      assert is_list(npc.attributes)
      assert length(npc.attributes) == 8

      attr = Enum.find(npc.attributes, fn a -> a.attribute_id == 0 end)
      assert attr != nil
      assert attr.value == 100
    end

    test "imports npc skills embedded array correctly" do
      npc = Ash.get!(NPC, "todd")
      assert is_list(npc.skills)
      assert length(npc.skills) == 27

      skill = Enum.find(npc.skills, fn s -> s.skill_id == 0 end)
      assert skill != nil
      assert skill.value == 86
    end

    test "imports npc_flags correctly" do
      npc = Ash.get!(NPC, "todd")
      assert is_list(npc.npc_flags)
      # todd has no flags set (autocalc: false, respawn: false, essential: false, female: false)
      assert npc.npc_flags == []
    end

    test "imports alert embedded type correctly" do
      npc = Ash.get!(NPC, "todd")
      assert npc.alert != nil
      assert npc.alert.fight == 30
      assert npc.alert.alarm == 100
    end

    test "creates corresponding ReferencableObject" do
      ref_obj = Ash.get!(ReferencableObject, "todd")
      assert ref_obj.type == :npc
    end

    test "imports transport destinations correctly" do
      # The Seyda Neen silt strider caravaner
      npc = Ash.get!(NPC, "darvame hleran", load: [transport_options: [:cell]])
      assert length(npc.transport_options) == 4

      destination = List.last(npc.transport_options)

      assert destination.coordinates.position.x == Decimal.new("-21318.73")
      assert destination.coordinates.position.y == Decimal.new("-18232.41")
      assert destination.coordinates.position.z == Decimal.new("1177.66")
      assert destination.cell_id == "-3,-3"
      assert destination.cell.name == "Balmora"
    end

    test "imports all npcs with ReferencableObject entries" do
      npc_count = Ash.count!(NPC)
      ref_count = Ash.count!(ReferencableObject, query: [filter: [type: :npc]])

      assert npc_count == ref_count,
             "NPC count (#{npc_count}) should match ReferencableObject count (#{ref_count})"
    end
  end

  # =============================================================================
  # Cell and CellReference Tests
  # =============================================================================

  describe "Cell" do
    test "imports correct count" do
      count = Ash.count!(Resdayn.Codex.World.Cell)
      assert count == 2538, "Expected 2538 cells, got #{count}"
    end

    test "imports interior cell data correctly" do
      cell = Ash.get!(Resdayn.Codex.World.Cell, "Balmora, South Wall Cornerclub")

      assert cell.name == "Balmora, South Wall Cornerclub"
      assert cell.grid_position == nil
      assert :interior in cell.cell_flags
      assert cell.source_file_ids == ["Morrowind.esm"]
    end

    test "imports exterior cell data correctly" do
      cell = Ash.get!(Resdayn.Codex.World.Cell, "0,0")

      assert cell.grid_position == [0, 0]
      assert cell.region_id == "Ashlands Region"
      assert cell.source_file_ids == ["Morrowind.esm"]
    end

    test "imports cell light embedded type correctly" do
      # Find an interior cell with light data
      cell = Ash.get!(Resdayn.Codex.World.Cell, "Balmora, South Wall Cornerclub")

      if cell.light do
        assert is_map(cell.light)
      end
    end
  end

  describe "CellReference" do
    test "imports references for a cell" do
      require Ash.Query

      references =
        Resdayn.Codex.World.Cell.CellReference
        |> Ash.Query.filter(cell_id == "Balmora, South Wall Cornerclub")
        |> Ash.read!()

      assert length(references) > 0
    end

    test "imports reference data correctly" do
      require Ash.Query

      references =
        Resdayn.Codex.World.Cell.CellReference
        |> Ash.Query.filter(cell_id == "Balmora, South Wall Cornerclub")
        |> Ash.read!()

      reference = Enum.find(references, fn r -> r.reference_id != nil end)
      assert reference != nil
      assert reference.coordinates != nil
      assert reference.source_file_ids == ["Morrowind.esm"]
    end

    test "imports transport details correctly (eg. for doors)" do
      require Ash.Query

      reference =
        Resdayn.Codex.World.Cell.CellReference
        |> Ash.Query.filter(
          cell_id == "Maar Gan, Tashpi Ashibael's Hut" and
            reference_id == "in_redoran_hut_door_01"
        )
        |> Ash.Query.load(transport_to: [:cell])
        |> Ash.read_one!()

      assert reference.transport_to.cell_id == "-3,12"
      assert reference.transport_to.cell.name == "Maar Gan"
    end

    test "imports total reference count" do
      count = Ash.count!(Resdayn.Codex.World.Cell.CellReference)
      # Morrowind.esm has ~316k references
      assert count == 316_116, "Expected 316,116 references, got #{count}"
    end
  end

  # =============================================================================
  # Relationship Import Tests
  # =============================================================================

  describe "RaceSkillBonus" do
    test "imports correct count" do
      count = Ash.count!(Resdayn.Codex.Characters.Race.SkillBonus)
      # 10 races with varying skill bonuses
      assert count == 62, "Expected 62 race skill bonuses, got #{count}"
    end

    test "imports race skill bonus data correctly" do
      require Ash.Query

      bonuses =
        Resdayn.Codex.Characters.Race.SkillBonus
        |> Ash.Query.filter(race_id == "Dark Elf")
        |> Ash.read!()

      assert length(bonuses) == 7
      assert Enum.all?(bonuses, fn b -> b.bonus > 0 end)
      assert Enum.all?(bonuses, fn b -> b.source_file_ids == ["Morrowind.esm"] end)
    end
  end

  describe "FactionReaction" do
    test "imports faction reactions" do
      count = Ash.count!(Resdayn.Codex.Characters.Faction.Reaction)
      assert count > 0, "Expected faction reactions to be imported"
    end

    test "imports faction reaction data correctly" do
      require Ash.Query

      reactions =
        Resdayn.Codex.Characters.Faction.Reaction
        |> Ash.Query.filter(source_id == "Fighters Guild")
        |> Ash.read!()

      assert length(reactions) > 0
      assert Enum.all?(reactions, fn r -> r.source_file_ids == ["Morrowind.esm"] end)
    end
  end

  describe "InventoryItem (NPC)" do
    test "imports npc inventory items" do
      require Ash.Query

      # Find NPCs with inventory
      items =
        Resdayn.Codex.World.InventoryItem
        |> Ash.Query.limit(100)
        |> Ash.read!()

      assert length(items) > 0
    end

    test "imports inventory item data correctly" do
      require Ash.Query

      items =
        Resdayn.Codex.World.InventoryItem
        |> Ash.Query.filter(holder_ref_id == "arrille")
        |> Ash.read!()

      if length(items) > 0 do
        item = hd(items)
        assert item.count >= 1
        assert item.source_file_ids == ["Morrowind.esm"]
      end
    end
  end

  # =============================================================================
  # Dialogue Tests
  # =============================================================================

  describe "DialogueTopic" do
    test "imports correct count" do
      count = Ash.count!(Resdayn.Codex.Dialogue.Topic)
      assert count == 1726, "Expected 1726 dialogue topics, got #{count}"
    end

    test "imports dialogue topic data correctly" do
      topic = Ash.get!(Resdayn.Codex.Dialogue.Topic, "Background")
      assert topic != nil
      assert topic.source_file_ids == ["Morrowind.esm"]
    end
  end

  describe "DialogueResponse" do
    test "imports dialogue responses" do
      count = Ash.count!(Resdayn.Codex.Dialogue.Response)
      assert count == 21204, "Expected 21204 dialogue responses, got #{count}"
    end

    test "imports dialogue response data correctly" do
      require Ash.Query

      responses =
        Resdayn.Codex.Dialogue.Response
        |> Ash.Query.limit(10)
        |> Ash.read!()

      assert length(responses) > 0
      response = hd(responses)
      assert response.source_file_ids == ["Morrowind.esm"]
    end
  end

  describe "Quest" do
    test "imports quests" do
      count = Ash.count!(Resdayn.Codex.Dialogue.Quest)
      assert count == 632, "Expected 632 quests, got #{count}"
    end

    test "imports quest data correctly" do
      quest = Ash.get!(Resdayn.Codex.Dialogue.Quest, "A1_1_FindSpymaster")
      assert quest != nil
      assert quest.name != nil
      assert quest.source_file_ids == ["Morrowind.esm"]
    end
  end

  describe "JournalEntry" do
    test "imports journal entries" do
      count = Ash.count!(Resdayn.Codex.Dialogue.JournalEntry)
      assert count == 2489, "Expected 2489 journal entries, got #{count}"
    end

    test "imports journal entry data correctly" do
      require Ash.Query

      entries =
        Resdayn.Codex.Dialogue.JournalEntry
        |> Ash.Query.filter(quest_id == "A1_1_FindSpymaster")
        |> Ash.read!()

      assert length(entries) > 0
      entry = hd(entries)
      assert entry.index >= 0
      assert entry.source_file_ids == ["Morrowind.esm"]
    end
  end

  # =============================================================================
  # Re-import Behavior Tests
  # =============================================================================

  describe "re-import behavior" do
    test "re-importing doesn't duplicate source files" do
      records = get_morrowind_records()

      config =
        Resdayn.Importer.Record.GameSetting.process(records, filename: "Morrowind.esm")

      original = Ash.get!(GameSetting, "sMonthMorningstar")
      original_source_files = original.source_file_ids

      # Re-import with same file
      {:ok, _} =
        FastBulkImport.import(config.records, config.resource, source_file_id: "Morrowind.esm")

      reimported = Ash.get!(GameSetting, "sMonthMorningstar")
      assert reimported.source_file_ids == original_source_files
    end

    test "importing with new source file merges source_file_ids" do
      records = get_morrowind_records()

      config =
        Resdayn.Importer.Record.GameSetting.process(records, filename: "Morrowind.esm")

      original = Ash.get!(GameSetting, "sMonthMorningstar")
      refute "TestMod.esm" in original.source_file_ids

      # Import with new source file
      {:ok, _} =
        FastBulkImport.import(config.records, config.resource, source_file_id: "TestMod.esm")

      updated = Ash.get!(GameSetting, "sMonthMorningstar")
      assert "Morrowind.esm" in updated.source_file_ids
      assert "TestMod.esm" in updated.source_file_ids

      # Clean up
      {:ok, _} =
        FastBulkImport.import(config.records, config.resource, source_file_id: "Morrowind.esm")
    end

    test "upsert updates values correctly" do
      records = get_morrowind_records()

      config =
        Resdayn.Importer.Record.GameSetting.process(records, filename: "Morrowind.esm")

      original = Ash.get!(GameSetting, "sMonthMorningstar")
      original_value = original.value

      # Modify and re-import
      modified_records =
        Enum.map(config.records, fn record ->
          if record.id == "sMonthMorningstar" do
            %{record | value: "Test Modified Month"}
          else
            record
          end
        end)

      {:ok, _} =
        FastBulkImport.import(modified_records, config.resource, source_file_id: "TestUpdate.esm")

      updated = Ash.get!(GameSetting, "sMonthMorningstar")
      assert updated.value == %Ash.Union{type: :string, value: "Test Modified Month"}

      # Restore
      {:ok, _} =
        FastBulkImport.import(config.records, config.resource, source_file_id: "Morrowind.esm")

      restored = Ash.get!(GameSetting, "sMonthMorningstar")
      assert restored.value == original_value
    end

    test "BulkRelationshipImport updates optional fields even when first record omits them" do
      # Regression test: replace_columns was computed from only the first record.
      # If the first record omitted an optional field but later records had values,
      # those fields wouldn't be in the ON CONFLICT UPDATE clause, so re-imports
      # wouldn't update those fields.

      require Ash.Query
      alias Resdayn.Codex.Changes.BulkRelationshipImport
      alias Resdayn.Codex.World.Cell.CellReference

      # Find two cells with references - one without transport_to, one with
      ref_without_transport =
        CellReference
        |> Ash.Query.filter(is_nil(transport_to))
        |> Ash.Query.limit(1)
        |> Ash.read_one!()

      ref_with_transport =
        CellReference
        |> Ash.Query.filter(not is_nil(transport_to))
        |> Ash.Query.limit(1)
        |> Ash.read_one!()

      # Build import records with the first record OMITTING transport_to entirely
      # (not setting it to nil, but not including the key at all)
      # This triggers the bug because prepare_for_insert won't add the key to the
      # prepared map if the value is nil/missing
      first_ref_data = %{
        id: ref_without_transport.id,
        reference_id: ref_without_transport.reference_id,
        coordinates: ref_without_transport.coordinates
        # transport_to key is intentionally OMITTED, not set to nil
      }

      records = [
        %{
          id: ref_without_transport.cell_id,
          new_references: [first_ref_data]
        },
        %{
          id: ref_with_transport.cell_id,
          new_references: [
            %{
              id: ref_with_transport.id,
              reference_id: ref_with_transport.reference_id,
              coordinates: ref_with_transport.coordinates,
              # Change the transport coordinates to verify update works
              transport_to: %{
                ref_with_transport.transport_to
                | coordinates: %{
                    position: %{x: 999.0, y: 999.0, z: 999.0},
                    rotation: %{x: 0.0, y: 0.0, z: 0.0}
                  }
              }
            }
          ]
        }
      ]

      {:ok, _} =
        BulkRelationshipImport.import(
          records,
          parent_resource: Resdayn.Codex.World.Cell,
          related_resource: CellReference,
          parent_key: :cell_id,
          id_field: :id,
          relationship_key: :new_references,
          on_missing: :ignore,
          source_file_id: "Morrowind.esm"
        )

      # Verify the transport_to field was updated despite first record omitting it
      updated_ref =
        Ash.get!(CellReference, %{id: ref_with_transport.id, cell_id: ref_with_transport.cell_id})

      assert updated_ref.transport_to.coordinates.position.x == Decimal.new("999.0"),
             "transport_to should be updated even when first record in batch omits transport_to key"
    end
  end
end
