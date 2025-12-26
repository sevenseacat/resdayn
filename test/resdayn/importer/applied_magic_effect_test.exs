defmodule Resdayn.Importer.AppliedMagicEffectTest do
  use Resdayn.DataCase, async: true

  alias Resdayn.Importer.Record.AppliedMagicEffect, as: AppliedMagicEffectImporter

  describe "process/2" do
    test "collects effects from spells with correct parent_type" do
      records = [
        # Magic effect template for lookup
        %{
          type: Resdayn.Parser.Record.MagicEffect,
          flags: %{},
          data: %{
            id: 14,
            skill_id: nil,
            attribute_id: nil,
            game_setting_id: "sMagicFireDamage"
          }
        },
        %{
          type: Resdayn.Parser.Record.Spell,
          flags: %{},
          data: %{
            id: "test_spell",
            name: "Test Spell",
            type: :spell,
            cost: 10,
            flags: %{},
            enchantments: [
              %{
                duration: 30,
                magnitude: %{min: 5, max: 10},
                range: :touch,
                area: 0,
                applied_magic_effect: %{
                  magic_effect_id: 14,
                  skill_id: nil,
                  attribute_id: nil
                }
              }
            ]
          }
        }
      ]

      result = AppliedMagicEffectImporter.process(records, [])

      assert result.type == :fast_bulk
      assert result.resource == Resdayn.Codex.Mechanics.AppliedMagicEffect
      assert result.conflict_keys == [:parent_type, :parent_id, :index]

      assert length(result.records) == 1
      [effect] = result.records

      assert effect.parent_type == :spell
      assert effect.parent_id == "test_spell"
      assert effect.index == 0
      assert effect.magic_effect_id == "14::"
      assert effect.duration == 30
      assert effect.magnitude == %{min: 5, max: 10}
      assert effect.range == :touch
      assert effect.area == 0
    end

    test "collects effects from potions with correct parent_type" do
      records = [
        %{
          type: Resdayn.Parser.Record.MagicEffect,
          flags: %{},
          data: %{
            id: 79,
            skill_id: nil,
            attribute_id: nil,
            game_setting_id: "sMagicInvisibility"
          }
        },
        %{
          type: Resdayn.Parser.Record.Potion,
          flags: %{},
          data: %{
            id: "test_potion",
            name: "Test Potion",
            flags: %{autocalc: false},
            effects: [
              %{
                duration: 60,
                magnitude: %{min: 10, max: 20},
                range: :self,
                area: 0,
                applied_magic_effect: %{
                  magic_effect_id: 79,
                  skill_id: nil,
                  attribute_id: nil
                }
              }
            ]
          }
        }
      ]

      result = AppliedMagicEffectImporter.process(records, [])

      assert length(result.records) == 1
      [effect] = result.records

      assert effect.parent_type == :potion
      assert effect.parent_id == "test_potion"
      assert effect.index == 0
      assert effect.magic_effect_id == "79::"
    end

    test "collects effects from enchantments with correct parent_type" do
      records = [
        %{
          type: Resdayn.Parser.Record.MagicEffect,
          flags: %{},
          data: %{
            id: 85,
            skill_id: nil,
            attribute_id: nil,
            game_setting_id: "sMagicAbsorbHealth"
          }
        },
        %{
          type: Resdayn.Parser.Record.Enchantment,
          flags: %{},
          data: %{
            id: "test_enchant",
            type: :constant,
            cost: 50,
            charge: 100,
            flags: %{autocalc: false},
            enchantments: [
              %{
                duration: 0,
                magnitude: %{min: 1, max: 5},
                range: :self,
                area: 0,
                applied_magic_effect: %{
                  magic_effect_id: 85,
                  skill_id: nil,
                  attribute_id: nil
                }
              }
            ]
          }
        }
      ]

      result = AppliedMagicEffectImporter.process(records, [])

      assert length(result.records) == 1
      [effect] = result.records

      assert effect.parent_type == :enchantment
      assert effect.parent_id == "test_enchant"
      assert effect.index == 0
    end

    test "preserves effect ordering with index" do
      records = [
        %{
          type: Resdayn.Parser.Record.MagicEffect,
          flags: %{},
          data: %{id: 14, skill_id: nil, attribute_id: nil, game_setting_id: "sMagicFireDamage"}
        },
        %{
          type: Resdayn.Parser.Record.MagicEffect,
          flags: %{},
          data: %{id: 15, skill_id: nil, attribute_id: nil, game_setting_id: "sMagicFrostDamage"}
        },
        %{
          type: Resdayn.Parser.Record.MagicEffect,
          flags: %{},
          data: %{id: 16, skill_id: nil, attribute_id: nil, game_setting_id: "sMagicShockDamage"}
        },
        %{
          type: Resdayn.Parser.Record.Spell,
          flags: %{},
          data: %{
            id: "multi_effect_spell",
            name: "Multi Effect",
            type: :spell,
            cost: 30,
            flags: %{},
            enchantments: [
              %{
                duration: 10,
                magnitude: %{min: 1, max: 1},
                range: :self,
                area: 0,
                applied_magic_effect: %{magic_effect_id: 14, skill_id: nil, attribute_id: nil}
              },
              %{
                duration: 20,
                magnitude: %{min: 2, max: 2},
                range: :touch,
                area: 0,
                applied_magic_effect: %{magic_effect_id: 15, skill_id: nil, attribute_id: nil}
              },
              %{
                duration: 30,
                magnitude: %{min: 3, max: 3},
                range: :target,
                area: 5,
                applied_magic_effect: %{magic_effect_id: 16, skill_id: nil, attribute_id: nil}
              }
            ]
          }
        }
      ]

      result = AppliedMagicEffectImporter.process(records, [])

      assert length(result.records) == 3

      effects = Enum.sort_by(result.records, & &1.index)

      assert Enum.at(effects, 0).index == 0
      assert Enum.at(effects, 0).duration == 10
      assert Enum.at(effects, 0).magic_effect_id == "14::"

      assert Enum.at(effects, 1).index == 1
      assert Enum.at(effects, 1).duration == 20
      assert Enum.at(effects, 1).magic_effect_id == "15::"

      assert Enum.at(effects, 2).index == 2
      assert Enum.at(effects, 2).duration == 30
      assert Enum.at(effects, 2).magic_effect_id == "16::"
    end

    test "collects effects from all parent types in single pass" do
      records = [
        %{
          type: Resdayn.Parser.Record.MagicEffect,
          flags: %{},
          data: %{id: 14, skill_id: nil, attribute_id: nil, game_setting_id: "sMagicFireDamage"}
        },
        %{
          type: Resdayn.Parser.Record.Spell,
          flags: %{},
          data: %{
            id: "spell1",
            name: "Spell",
            type: :spell,
            cost: 10,
            flags: %{},
            enchantments: [
              %{
                duration: 10,
                magnitude: %{min: 1, max: 1},
                range: :self,
                area: 0,
                applied_magic_effect: %{magic_effect_id: 14, skill_id: nil, attribute_id: nil}
              }
            ]
          }
        },
        %{
          type: Resdayn.Parser.Record.Potion,
          flags: %{},
          data: %{
            id: "potion1",
            name: "Potion",
            flags: %{autocalc: false},
            effects: [
              %{
                duration: 20,
                magnitude: %{min: 2, max: 2},
                range: :self,
                area: 0,
                applied_magic_effect: %{magic_effect_id: 14, skill_id: nil, attribute_id: nil}
              }
            ]
          }
        },
        %{
          type: Resdayn.Parser.Record.Enchantment,
          flags: %{},
          data: %{
            id: "enchant1",
            type: :constant,
            cost: 50,
            charge: 100,
            flags: %{autocalc: false},
            enchantments: [
              %{
                duration: 30,
                magnitude: %{min: 3, max: 3},
                range: :self,
                area: 0,
                applied_magic_effect: %{magic_effect_id: 14, skill_id: nil, attribute_id: nil}
              }
            ]
          }
        }
      ]

      result = AppliedMagicEffectImporter.process(records, [])

      assert length(result.records) == 3

      parent_types = Enum.map(result.records, & &1.parent_type) |> Enum.sort()
      assert parent_types == [:enchantment, :potion, :spell]
    end

    test "handles skill-based magic effects" do
      records = [
        %{
          type: Resdayn.Parser.Record.MagicEffect,
          flags: %{},
          data: %{
            id: 21,
            skill_id: 5,
            attribute_id: nil,
            game_setting_id: "sMagicFortifySkill"
          }
        },
        %{
          type: Resdayn.Parser.Record.Spell,
          flags: %{},
          data: %{
            id: "skill_spell",
            name: "Fortify Skill",
            type: :spell,
            cost: 20,
            flags: %{},
            enchantments: [
              %{
                duration: 60,
                magnitude: %{min: 10, max: 10},
                range: :self,
                area: 0,
                applied_magic_effect: %{
                  magic_effect_id: 21,
                  skill_id: 5,
                  attribute_id: nil
                }
              }
            ]
          }
        }
      ]

      result = AppliedMagicEffectImporter.process(records, [])

      [effect] = result.records
      assert effect.magic_effect_id == "21:5:"
    end

    test "handles attribute-based magic effects" do
      records = [
        %{
          type: Resdayn.Parser.Record.MagicEffect,
          flags: %{},
          data: %{
            id: 17,
            skill_id: nil,
            attribute_id: 3,
            game_setting_id: "sMagicFortifyAttribute"
          }
        },
        %{
          type: Resdayn.Parser.Record.Spell,
          flags: %{},
          data: %{
            id: "attr_spell",
            name: "Fortify Attribute",
            type: :spell,
            cost: 20,
            flags: %{},
            enchantments: [
              %{
                duration: 60,
                magnitude: %{min: 10, max: 10},
                range: :self,
                area: 0,
                applied_magic_effect: %{
                  magic_effect_id: 17,
                  skill_id: nil,
                  attribute_id: 3
                }
              }
            ]
          }
        }
      ]

      result = AppliedMagicEffectImporter.process(records, [])

      [effect] = result.records
      assert effect.magic_effect_id == "17::3"
    end

    test "returns empty records list when no effects exist" do
      records = [
        %{
          type: Resdayn.Parser.Record.Spell,
          flags: %{},
          data: %{
            id: "empty_spell",
            name: "No Effects",
            type: :spell,
            cost: 0,
            flags: %{},
            enchantments: []
          }
        }
      ]

      result = AppliedMagicEffectImporter.process(records, [])

      assert result.records == []
    end
  end
end
