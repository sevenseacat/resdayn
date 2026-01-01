defmodule Resdayn.Importer.Quests.ScriptParserTest do
  use Resdayn.DataCase, async: true

  alias Resdayn.Importer.Quests.{Script, ScriptParser}

  @script_simple """
  Journal "MV_DeadTaxman" 100
  RemoveItem "Gold_001" 500
  Player->AddItem "Gold_001" 500
  Goodbye
  """

  @script_single_condition """
  if ( GetJournalIndex "MV_SlaveMule" <= 100 )
    Journal "MV_SlaveMule" 101
  endif
  """

  @script_else """
  if ( GetJournalIndex "Quest" == 10 )
    Journal "Quest" 20
  else
    Journal "Quest" 30
  endif
  """

  @script_elseif """
  if ( GetJournalIndex "MV_SlaveMule" <= 100 )
    Journal "MV_SlaveMule" 101
  elseif ( GetJournalIndex "MV_SlaveMule" == 102 )
    Journal "MV_SlaveMule" 103
  endif
  """

  @script_nested_conditions """
  if ( GetJournalIndex B5_RedoranHort >= 50 )
    if ( GetJournalIndex B6_HlaaluHort >= 50 )
      if ( GetJournalIndex B7_TelvanniHort >= 50 )
        Journal B8_All_Hortator 50
      endif
    endif
  endif
  """

  @script_death_condition """
  if ( GetDeadCount "Ahnia" > 0 )
    if ( GetJournalIndex "MS_ScrollSales" > 0 )
      if ( GetJournalIndex "MS_ScrollSales" < 40 )
        Journal MS_ScrollSales 40
      endif
    endif
  endif
  """

  @script_multiple_quests """
  if ( GetJournalIndex C3_DestroyDagoth == 20 )
    Journal C3_DestroyDagoth 50
    Journal A1_SleepersAwake 50
  endif
  """

  @script_effects_before_journal """
  if ( GetJournalIndex "MV_SlaveMule" <= 100 )
    AddItem "Ingred_Moon_Sugar_01" 20
    Journal "MV_SlaveMule" 101
  endif
  """

  @script_effects_before_and_after """
  if ( GetJournalIndex "MV_SlaveMule" <= 100 )
    AddItem "Ingred_Moon_Sugar_01" 20
    Journal "MV_SlaveMule" 101
    ModDisposition 15
  endif
  """

  @script_shared_effects """
  if ( GetJournalIndex C3_DestroyDagoth == 20 )
    "ring of azura"->Enable
    Journal C3_DestroyDagoth 50
    Journal A1_SleepersAwake 50
    ModReputation 10
  endif
  """

  @script_different_blocks """
  if ( GetJournalIndex Quest < 50 )
    AddItem "reward1" 1
    Journal Quest 50
  endif

  if ( GetJournalIndex Quest >= 50 )
    AddItem "reward2" 1
    Journal Quest 100
  endif
  """

  @script_pc_cell_condition """
  begin ScriptPcCellCondition

  short currentCell
  long longtimeago

  if ( GetPCCell "Ebonheart, Argonian Mission" == 1 )
    Journal MV_SlaveMule 114
  endif

  end
  """

  @script_on_death_condition """
  if ( OnDeath == 1 )
    Journal "SomeQuest" 50
  endif
  """

  @script_hierarchical_levels """
  if ( GetJournalIndex MainQuest >= 10 )
    AddTopic "rumors"
    if ( GetDeadCount "villain" >= 1 )
      Player->AddItem "gold_001" 500
      Journal MainQuest 20
      if ( GetItemCount "secret_note" >= 1 )
        Journal SideQuest 10
        AddTopic "secret"
      endif
      ModPCFacRep 5 "Fighters Guild"
      Journal MainQuest 30
    endif
    Journal MainQuest 15
  endif
  """

  @script_with_start_script """
  Journal "Quest" 20
  StartScript "OtherScript"
  """

  describe "parse" do
    test "simple scripts" do
      expected = %Script.Ast{
        name: nil,
        locals: [],
        body: [
          %Script.Journal{quest_id: "mv_deadtaxman", index: 100},
          %Script.Effect{
            type: :remove_item,
            data: %{subject: :self, item_id: "gold_001", count: 500}
          },
          %Script.Effect{
            type: :add_item,
            data: %{subject: :player, item_id: "gold_001", count: 500}
          },
          %Script.Effect{type: :goodbye, data: %{}}
        ]
      }

      assert ScriptParser.parse(@script_simple) == expected
    end

    test "script with single condition" do
      expected = %Script.Ast{
        name: nil,
        locals: [],
        body: [
          %Script.IfBlock{
            condition: %{type: :journal_index, target: "mv_slavemule", operator: :<=, value: 100},
            body: [
              %Script.Journal{quest_id: "mv_slavemule", index: 101}
            ],
            else_clause: nil
          }
        ]
      }

      assert ScriptParser.parse(@script_single_condition) == expected
    end

    test "script with else" do
      expected = %Script.Ast{
        name: nil,
        locals: [],
        body: [
          %Script.IfBlock{
            condition: %{type: :journal_index, target: "quest", operator: :==, value: 10},
            body: [
              %Script.Journal{quest_id: "quest", index: 20}
            ],
            else_clause: [
              %Script.Journal{quest_id: "quest", index: 30}
            ]
          }
        ]
      }

      assert ScriptParser.parse(@script_else) == expected
    end

    test "script with elseif" do
      expected = %Script.Ast{
        name: nil,
        locals: [],
        body: [
          %Script.IfBlock{
            condition: %{type: :journal_index, target: "mv_slavemule", operator: :<=, value: 100},
            body: [
              %Script.Journal{quest_id: "mv_slavemule", index: 101}
            ],
            else_clause: %Script.IfBlock{
              condition: %{
                type: :journal_index,
                target: "mv_slavemule",
                operator: :==,
                value: 102
              },
              body: [
                %Script.Journal{quest_id: "mv_slavemule", index: 103}
              ],
              else_clause: nil
            }
          }
        ]
      }

      assert ScriptParser.parse(@script_elseif) == expected
    end

    test "script with nested conditions" do
      expected = %Script.Ast{
        name: nil,
        locals: [],
        body: [
          %Script.IfBlock{
            condition: %{type: :journal_index, target: "b5_redoranhort", operator: :>=, value: 50},
            body: [
              %Script.IfBlock{
                condition: %{
                  type: :journal_index,
                  target: "b6_hlaaluhort",
                  operator: :>=,
                  value: 50
                },
                body: [
                  %Script.IfBlock{
                    condition: %{
                      type: :journal_index,
                      target: "b7_telvannihort",
                      operator: :>=,
                      value: 50
                    },
                    body: [
                      %Script.Journal{quest_id: "b8_all_hortator", index: 50}
                    ],
                    else_clause: nil
                  }
                ],
                else_clause: nil
              }
            ],
            else_clause: nil
          }
        ]
      }

      assert ScriptParser.parse(@script_nested_conditions) == expected
    end

    test "script with death condition" do
      expected = %Script.Ast{
        name: nil,
        locals: [],
        body: [
          %Script.IfBlock{
            condition: %{type: :dead_count, target: "ahnia", operator: :>, value: 0},
            body: [
              %Script.IfBlock{
                condition: %{
                  type: :journal_index,
                  target: "ms_scrollsales",
                  operator: :>,
                  value: 0
                },
                body: [
                  %Script.IfBlock{
                    condition: %{
                      type: :journal_index,
                      target: "ms_scrollsales",
                      operator: :<,
                      value: 40
                    },
                    body: [
                      %Script.Journal{quest_id: "ms_scrollsales", index: 40}
                    ],
                    else_clause: nil
                  }
                ],
                else_clause: nil
              }
            ],
            else_clause: nil
          }
        ]
      }

      assert ScriptParser.parse(@script_death_condition) == expected
    end

    test "script with multiple quests" do
      expected = %Script.Ast{
        name: nil,
        locals: [],
        body: [
          %Script.IfBlock{
            condition: %{
              type: :journal_index,
              target: "c3_destroydagoth",
              operator: :==,
              value: 20
            },
            body: [
              %Script.Journal{quest_id: "c3_destroydagoth", index: 50},
              %Script.Journal{quest_id: "a1_sleepersawake", index: 50}
            ],
            else_clause: nil
          }
        ]
      }

      assert ScriptParser.parse(@script_multiple_quests) == expected
    end

    test "script with effects before journal" do
      expected = %Script.Ast{
        name: nil,
        locals: [],
        body: [
          %Script.IfBlock{
            condition: %{type: :journal_index, target: "mv_slavemule", operator: :<=, value: 100},
            body: [
              %Script.Effect{
                type: :add_item,
                data: %{subject: :self, item_id: "ingred_moon_sugar_01", count: 20}
              },
              %Script.Journal{quest_id: "mv_slavemule", index: 101}
            ],
            else_clause: nil
          }
        ]
      }

      assert ScriptParser.parse(@script_effects_before_journal) == expected
    end

    test "script with effects before and after journal" do
      expected = %Script.Ast{
        name: nil,
        locals: [],
        body: [
          %Script.IfBlock{
            condition: %{type: :journal_index, target: "mv_slavemule", operator: :<=, value: 100},
            body: [
              %Script.Effect{
                type: :add_item,
                data: %{subject: :self, item_id: "ingred_moon_sugar_01", count: 20}
              },
              %Script.Journal{quest_id: "mv_slavemule", index: 101},
              %Script.Effect{type: :mod_disposition, data: %{subject: :self, value: 15}}
            ],
            else_clause: nil
          }
        ]
      }

      assert ScriptParser.parse(@script_effects_before_and_after) == expected
    end

    test "script with shared effects" do
      expected = %Script.Ast{
        name: nil,
        locals: [],
        body: [
          %Script.IfBlock{
            condition: %{
              type: :journal_index,
              target: "c3_destroydagoth",
              operator: :==,
              value: 20
            },
            body: [
              %Script.Effect{type: :enable, data: %{subject: "ring of azura"}},
              %Script.Journal{quest_id: "c3_destroydagoth", index: 50},
              %Script.Journal{quest_id: "a1_sleepersawake", index: 50},
              %Script.Effect{type: :mod_reputation, data: %{subject: :self, value: 10}}
            ],
            else_clause: nil
          }
        ]
      }

      assert ScriptParser.parse(@script_shared_effects) == expected
    end

    test "script with different blocks" do
      expected = %Script.Ast{
        name: nil,
        locals: [],
        body: [
          %Script.IfBlock{
            condition: %{type: :journal_index, target: "quest", operator: :<, value: 50},
            body: [
              %Script.Effect{
                type: :add_item,
                data: %{subject: :self, item_id: "reward1", count: 1}
              },
              %Script.Journal{quest_id: "quest", index: 50}
            ],
            else_clause: nil
          },
          %Script.IfBlock{
            condition: %{type: :journal_index, target: "quest", operator: :>=, value: 50},
            body: [
              %Script.Effect{
                type: :add_item,
                data: %{subject: :self, item_id: "reward2", count: 1}
              },
              %Script.Journal{quest_id: "quest", index: 100}
            ],
            else_clause: nil
          }
        ]
      }

      assert ScriptParser.parse(@script_different_blocks) == expected
    end

    test "script with PCCell condition (and supports)" do
      expected = %Script.Ast{
        name: "scriptpccellcondition",
        locals: ["currentcell", "longtimeago"],
        body: [
          %Script.IfBlock{
            condition: %{
              type: :pc_cell,
              target: "ebonheart, argonian mission",
              operator: :==,
              value: 1
            },
            body: [
              %Script.Journal{quest_id: "mv_slavemule", index: 114}
            ],
            else_clause: nil
          }
        ]
      }

      assert ScriptParser.parse(@script_pc_cell_condition) == expected
    end

    test "script with OnDeath condition" do
      expected = %Script.Ast{
        name: nil,
        locals: [],
        body: [
          %Script.IfBlock{
            condition: %{type: :on_death, subject: :self, operator: :==, value: 1},
            body: [
              %Script.Journal{quest_id: "somequest", index: 50}
            ],
            else_clause: nil
          }
        ]
      }

      assert ScriptParser.parse(@script_on_death_condition) == expected
    end

    test "script with hierarchical conditions" do
      expected = %Script.Ast{
        name: nil,
        locals: [],
        body: [
          %Script.IfBlock{
            condition: %{type: :journal_index, target: "mainquest", operator: :>=, value: 10},
            body: [
              %Script.Effect{type: :add_topic, data: %{topic_id: "rumors"}},
              %Script.IfBlock{
                condition: %{type: :dead_count, target: "villain", operator: :>=, value: 1},
                body: [
                  %Script.Effect{
                    type: :add_item,
                    data: %{subject: :player, item_id: "gold_001", count: 500}
                  },
                  %Script.Journal{quest_id: "mainquest", index: 20},
                  %Script.IfBlock{
                    condition: %{
                      type: :item_count,
                      subject: :self,
                      target: "secret_note",
                      operator: :>=,
                      value: 1
                    },
                    body: [
                      %Script.Journal{quest_id: "sidequest", index: 10},
                      %Script.Effect{type: :add_topic, data: %{topic_id: "secret"}}
                    ],
                    else_clause: nil
                  },
                  %Script.Effect{
                    type: :mod_faction_reputation,
                    data: %{faction_id: "fighters guild", value: 5}
                  },
                  %Script.Journal{quest_id: "mainquest", index: 30}
                ],
                else_clause: nil
              },
              %Script.Journal{quest_id: "mainquest", index: 15}
            ],
            else_clause: nil
          }
        ]
      }

      assert ScriptParser.parse(@script_hierarchical_levels) == expected
    end

    test "script with start script" do
      expected = %Script.Ast{
        name: nil,
        locals: [],
        body: [
          %Script.Journal{quest_id: "quest", index: 20},
          %Script.Effect{type: :start_script, data: %{script_id: "otherscript"}}
        ]
      }

      assert ScriptParser.parse(@script_with_start_script) == expected
    end
  end

  describe "extract_journal_commands" do
    test "simple scripts" do
      actual = ScriptParser.extract_journal_commands(@script_simple)

      assert actual == [
               %{
                 quest_id: "mv_deadtaxman",
                 index: 100,
                 effects: [
                   %{type: :remove_item, subject: :self, item_id: "gold_001", count: 500},
                   %{type: :add_item, subject: :player, item_id: "gold_001", count: 500},
                   %{type: :goodbye}
                 ],
                 conditions: []
               }
             ]
    end

    test "script with single condition" do
      actual = ScriptParser.extract_journal_commands(@script_single_condition)

      assert actual == [
               %{
                 quest_id: "mv_slavemule",
                 index: 101,
                 effects: [],
                 conditions: [
                   %{
                     type: :journal_index,
                     target: "mv_slavemule",
                     operator: :<=,
                     value: 100
                   }
                 ]
               }
             ]
    end

    test "script with elseif pops previous condition" do
      actual = ScriptParser.extract_journal_commands(@script_elseif)

      assert actual == [
               %{
                 quest_id: "mv_slavemule",
                 index: 101,
                 effects: [],
                 conditions: [
                   %{
                     type: :journal_index,
                     target: "mv_slavemule",
                     operator: :<=,
                     value: 100
                   }
                 ]
               },
               %{
                 quest_id: "mv_slavemule",
                 index: 103,
                 effects: [],
                 conditions: [
                   %{type: :journal_index, target: "mv_slavemule", operator: :==, value: 102}
                 ]
               }
             ]
    end

    test "script with nested conditions" do
      actual = ScriptParser.extract_journal_commands(@script_nested_conditions)

      assert actual == [
               %{
                 quest_id: "b8_all_hortator",
                 index: 50,
                 effects: [],
                 conditions: [
                   %{type: :journal_index, target: "b5_redoranhort", operator: :>=, value: 50},
                   %{type: :journal_index, target: "b6_hlaaluhort", operator: :>=, value: 50},
                   %{type: :journal_index, target: "b7_telvannihort", operator: :>=, value: 50}
                 ]
               }
             ]
    end

    test "script with death condition" do
      actual = ScriptParser.extract_journal_commands(@script_death_condition)

      assert actual == [
               %{
                 quest_id: "ms_scrollsales",
                 index: 40,
                 effects: [],
                 conditions: [
                   %{type: :dead_count, target: "ahnia", operator: :>, value: 0},
                   %{type: :journal_index, target: "ms_scrollsales", operator: :>, value: 0},
                   %{type: :journal_index, target: "ms_scrollsales", operator: :<, value: 40}
                 ]
               }
             ]
    end

    test "script sets multiple quests" do
      actual = ScriptParser.extract_journal_commands(@script_multiple_quests)

      # Both journals share the same (empty) effects from the block
      assert actual == [
               %{
                 quest_id: "c3_destroydagoth",
                 index: 50,
                 effects: [],
                 conditions: [
                   %{type: :journal_index, target: "c3_destroydagoth", operator: :==, value: 20}
                 ]
               },
               %{
                 quest_id: "a1_sleepersawake",
                 index: 50,
                 effects: [],
                 conditions: [
                   %{type: :journal_index, target: "c3_destroydagoth", operator: :==, value: 20}
                 ]
               }
             ]
    end

    test "script with effects before journal command" do
      actual = ScriptParser.extract_journal_commands(@script_effects_before_journal)

      assert [
               %{
                 quest_id: "mv_slavemule",
                 index: 101,
                 effects: [
                   %{type: :add_item, subject: :self, item_id: "ingred_moon_sugar_01", count: 20}
                 ],
                 conditions: [
                   %{type: :journal_index, target: "mv_slavemule", operator: :<=, value: 100}
                 ]
               }
             ] = actual
    end

    test "script with effects before and after journal command" do
      actual = ScriptParser.extract_journal_commands(@script_effects_before_and_after)

      assert [
               %{
                 quest_id: "mv_slavemule",
                 index: 101,
                 effects: [
                   %{type: :add_item, subject: :self, item_id: "ingred_moon_sugar_01", count: 20},
                   %{type: :mod_disposition, subject: :self, value: 15}
                 ],
                 conditions: [
                   %{type: :journal_index, target: "mv_slavemule", operator: :<=, value: 100}
                 ]
               }
             ] = actual
    end

    test "script with multiple quests shares block effects" do
      actual = ScriptParser.extract_journal_commands(@script_shared_effects)

      # Both journals get all effects from the block
      assert [
               %{
                 quest_id: "c3_destroydagoth",
                 index: 50,
                 effects: [
                   %{type: :enable, subject: "ring of azura"},
                   %{type: :mod_reputation, value: 10}
                 ],
                 conditions: [
                   %{type: :journal_index, target: "c3_destroydagoth", operator: :==, value: 20}
                 ]
               },
               %{
                 quest_id: "a1_sleepersawake",
                 index: 50,
                 effects: [
                   %{type: :enable, subject: "ring of azura"},
                   %{type: :mod_reputation, value: 10}
                 ],
                 conditions: [
                   %{type: :journal_index, target: "c3_destroydagoth", operator: :==, value: 20}
                 ]
               }
             ] = actual
    end

    test "different blocks have different effects" do
      actual = ScriptParser.extract_journal_commands(@script_different_blocks)

      assert [
               %{
                 quest_id: "quest",
                 index: 50,
                 effects: [%{type: :add_item, subject: :self, item_id: "reward1", count: 1}],
                 conditions: [%{type: :journal_index, target: "quest", operator: :<, value: 50}]
               },
               %{
                 quest_id: "quest",
                 index: 100,
                 effects: [%{type: :add_item, subject: :self, item_id: "reward2", count: 1}],
                 conditions: [
                   %{type: :journal_index, target: "quest", operator: :>=, value: 50}
                 ]
               }
             ] = actual
    end

    test "script with GetPCCell condition" do
      actual = ScriptParser.extract_journal_commands(@script_pc_cell_condition)

      assert actual == [
               %{
                 quest_id: "mv_slavemule",
                 index: 114,
                 effects: [],
                 conditions: [
                   %{
                     type: :pc_cell,
                     target: "ebonheart, argonian mission",
                     operator: :==,
                     value: 1
                   }
                 ]
               }
             ]
    end

    test "script with OnDeath condition" do
      actual = ScriptParser.extract_journal_commands(@script_on_death_condition)

      assert actual == [
               %{
                 quest_id: "somequest",
                 index: 50,
                 effects: [],
                 conditions: [%{type: :on_death, subject: :self, operator: :==, value: 1}]
               }
             ]
    end

    test "journal updates at different hierarchical levels with shared effects" do
      actual = ScriptParser.extract_journal_commands(@script_hierarchical_levels)

      assert Enum.sort(actual) ==
               Enum.sort([
                 # MainQuest 20: gets effects before it in the inner block
                 %{
                   quest_id: "mainquest",
                   index: 20,
                   conditions: [
                     %{type: :journal_index, target: "mainquest", operator: :>=, value: 10},
                     %{type: :dead_count, target: "villain", operator: :>=, value: 1}
                   ],
                   effects: [
                     %{type: :add_topic, topic_id: "rumors"},
                     %{type: :add_item, subject: :player, item_id: "gold_001", count: 500},
                     %{type: :mod_faction_reputation, faction_id: "fighters guild", value: 5}
                   ]
                 },
                 # SideQuest 10: gets all effects from outer blocks plus its own
                 %{
                   quest_id: "sidequest",
                   index: 10,
                   conditions: [
                     %{type: :journal_index, target: "mainquest", operator: :>=, value: 10},
                     %{type: :dead_count, target: "villain", operator: :>=, value: 1},
                     %{
                       type: :item_count,
                       subject: :self,
                       target: "secret_note",
                       operator: :>=,
                       value: 1
                     }
                   ],
                   effects: [
                     %{type: :add_topic, topic_id: "rumors"},
                     %{type: :add_item, subject: :player, item_id: "gold_001", count: 500},
                     %{type: :add_topic, topic_id: "secret"}
                   ]
                 },
                 # MainQuest 30: gets effects from its block level
                 %{
                   quest_id: "mainquest",
                   index: 30,
                   conditions: [
                     %{type: :journal_index, target: "mainquest", operator: :>=, value: 10},
                     %{type: :dead_count, target: "villain", operator: :>=, value: 1}
                   ],
                   effects: [
                     %{type: :add_topic, topic_id: "rumors"},
                     %{type: :add_item, subject: :player, item_id: "gold_001", count: 500},
                     %{type: :mod_faction_reputation, faction_id: "fighters guild", value: 5}
                   ]
                 },
                 # MainQuest 15: only outer block condition and effects
                 %{
                   quest_id: "mainquest",
                   index: 15,
                   conditions: [
                     %{type: :journal_index, target: "mainquest", operator: :>=, value: 10}
                   ],
                   effects: [
                     %{type: :add_topic, topic_id: "rumors"}
                   ]
                 }
               ])
    end
  end

  describe "parse_journal_command" do
    test "unquoted quest ID" do
      assert {"MV_SlaveMule", 100} =
               ScriptParser.parse_journal_command("journal MV_SlaveMule 100")
    end

    test "quoted quest ID" do
      assert {"MV_SlaveMule", 250} =
               ScriptParser.parse_journal_command("journal \"MV_SlaveMule\" 250")
    end

    test "quest ID with spaces" do
      assert {"this is a journal", 2} =
               ScriptParser.parse_journal_command("journal \"this is a journal\" 2")
    end

    test "not a valid journal command" do
      assert nil == ScriptParser.parse_journal_command("Goodbye")
    end
  end

  describe "parse_effect" do
    test "AddItem - explicit player subject" do
      assert %{count: 200, type: :add_item, subject: :player, item_id: "gold_001"} =
               ScriptParser.parse_effect("player->additem \"gold_001\" 200")

      assert %{count: 22, type: :add_item, subject: :player, item_id: "bk_froofroo"} =
               ScriptParser.parse_effect("player->additem bk_froofroo 22")

      assert %{count: 1, type: :add_item, subject: :player, item_id: "the_thing"} =
               ScriptParser.parse_effect("player->additem \"the_thing\"")
    end

    test "AddItem - implicit self subject" do
      assert %{count: 200, type: :add_item, subject: :self, item_id: "gold_001"} =
               ScriptParser.parse_effect("additem \"gold_001\" 200")

      assert %{count: 22, type: :add_item, subject: :self, item_id: "bk_froofroo"} =
               ScriptParser.parse_effect("additem bk_froofroo 22")

      assert %{count: 1, type: :add_item, subject: :self, item_id: "the_thing"} =
               ScriptParser.parse_effect("additem \"the_thing\"")
    end

    test "AddItem - explicit NPC subject" do
      assert %{count: 200, type: :add_item, subject: "fargoth", item_id: "gold_001"} =
               ScriptParser.parse_effect("fargoth->additem \"gold_001\" 200")

      assert %{count: 22, type: :add_item, subject: "arrille", item_id: "bk_froofroo"} =
               ScriptParser.parse_effect("\"arrille\"->additem bk_froofroo 22")

      assert %{count: 1, type: :add_item, subject: "chargen class", item_id: "the_thing"} =
               ScriptParser.parse_effect("\"chargen class\"->additem \"the_thing\"")
    end

    test "RemoveItem - explicit player subject" do
      assert %{count: 200, type: :remove_item, subject: :player, item_id: "gold_001"} =
               ScriptParser.parse_effect("player->removeitem \"gold_001\" 200")

      assert %{count: 22, type: :remove_item, subject: :player, item_id: "bk_froofroo"} =
               ScriptParser.parse_effect("player->removeitem bk_froofroo 22")

      assert %{count: 1, type: :remove_item, subject: :player, item_id: "the_thing"} =
               ScriptParser.parse_effect("player->removeitem \"the_thing\"")
    end

    test "RemoveItem - implicit self subject" do
      assert %{count: 200, type: :remove_item, subject: :self, item_id: "gold_001"} =
               ScriptParser.parse_effect("removeitem \"gold_001\" 200")

      assert %{count: 22, type: :remove_item, subject: :self, item_id: "bk_froofroo"} =
               ScriptParser.parse_effect("removeitem bk_froofroo 22")

      assert %{count: 1, type: :remove_item, subject: :self, item_id: "the_thing"} =
               ScriptParser.parse_effect("removeitem \"the_thing\"")
    end

    test "RemoveItem - explicit NPC subject" do
      assert %{count: 200, type: :remove_item, subject: "fargoth", item_id: "gold_001"} =
               ScriptParser.parse_effect("\"fargoth\"->removeitem \"gold_001\" 200")

      assert %{count: 22, type: :remove_item, subject: "arrille", item_id: "bk_froofroo"} =
               ScriptParser.parse_effect("\"arrille\"->removeitem bk_froofroo 22")

      assert %{count: 1, type: :remove_item, subject: "chargen class", item_id: "the_thing"} =
               ScriptParser.parse_effect("\"chargen class\"->removeitem \"the_thing\"")
    end

    test "Drop - implicit self subject" do
      assert %{type: :drop_item, subject: :self, item_id: "slave_bracer_left", count: 1} =
               ScriptParser.parse_effect("drop slave_bracer_left 1")
    end

    test "Drop - quoted item id" do
      assert %{type: :drop_item, subject: :self, item_id: "slave_bracer_right", count: 1} =
               ScriptParser.parse_effect("drop \"slave_bracer_right\" 1")
    end

    test "ModPCFacRep - positive value" do
      assert %{value: 10, type: :mod_faction_reputation, faction_id: "imperial legion"} =
               ScriptParser.parse_effect("modpcfacrep 10 \"imperial legion\"")
    end

    test "ModPCFacRep - negative value" do
      assert %{value: -5, type: :mod_faction_reputation, faction_id: "twin lamps"} =
               ScriptParser.parse_effect("modpcfacrep -5 \"twin lamps\"")
    end

    test "ModPCFacRep - unquoted faction" do
      assert %{value: 5, type: :mod_faction_reputation, faction_id: "temple"} =
               ScriptParser.parse_effect("modpcfacrep 5 temple")
    end

    test "PCRaiseRank - quoted faction" do
      assert %{subject: :player, type: :raise_rank, value: "mages guild"} =
               ScriptParser.parse_effect("pcraiserank \"mages guild\"")
    end

    test "PCRaiseRank - unquoted faction" do
      assert %{subject: :player, type: :raise_rank, value: "temple"} =
               ScriptParser.parse_effect("pcraiserank temple")
    end

    test "PCRaiseRank - no faction specified" do
      assert %{subject: :player, type: :raise_rank, value: nil} =
               ScriptParser.parse_effect("pcraiserank")
    end

    test "PCJoinFaction - quoted faction" do
      assert %{subject: :player, type: :join_faction, value: "morag tong"} =
               ScriptParser.parse_effect("pcjoinfaction \"morag tong\"")
    end

    test "PCJoinFaction - unquoted faction" do
      assert %{subject: :player, type: :join_faction, value: "ashlanders"} =
               ScriptParser.parse_effect("pcjoinfaction ashlanders")
    end

    test "ModReputation - with player subject" do
      assert %{type: :mod_reputation, value: 3} =
               ScriptParser.parse_effect("player->modreputation 3")
    end

    test "ModDisposition - positive value" do
      assert %{subject: :self, type: :mod_disposition, value: 15} =
               ScriptParser.parse_effect("moddisposition 15")
    end

    test "ModDisposition - negative value" do
      assert %{subject: :self, type: :mod_disposition, value: -10} =
               ScriptParser.parse_effect("moddisposition -10")
    end

    # Dialogue response ID 234315643133312879 - weird!
    test "ModDisposition - negative value with space" do
      assert %{subject: :self, type: :mod_disposition, value: -30} =
               ScriptParser.parse_effect("moddisposition - 30")
    end

    test "ModDisposition - with explicit subject" do
      assert %{subject: "arrille", type: :mod_disposition, value: 40} =
               ScriptParser.parse_effect("\"arrille\"->moddisposition 40")
    end

    test "ModDisposition - with explicit unquoted subject" do
      assert %{subject: "fargoth", type: :mod_disposition, value: 40} =
               ScriptParser.parse_effect("fargoth->moddisposition 40")
    end

    test "SetDisposition - without subject" do
      assert %{subject: :self, type: :set_disposition, value: 50} =
               ScriptParser.parse_effect("setdisposition 50")
    end

    test "SetDisposition - with explicit subject" do
      assert %{subject: "bolvyn venim", type: :set_disposition, value: 10} =
               ScriptParser.parse_effect("\"bolvyn venim\"->setdisposition 10")
    end

    test "AddTopic - quoted topic" do
      assert %{type: :add_topic, topic_id: "murder of processus vitellius"} =
               ScriptParser.parse_effect("addtopic \"murder of processus vitellius\"")
    end

    test "AddTopic - with player subject" do
      assert %{type: :add_topic, topic_id: "sculptor"} =
               ScriptParser.parse_effect("player->addtopic \"sculptor\"")
    end

    test "AddTopic - extra space after command" do
      assert %{type: :add_topic, topic_id: "the star is the key"} =
               ScriptParser.parse_effect("addtopic  \"the star is the key\"")
    end

    test "Enable - quoted subject" do
      assert %{type: :enable, subject: "npc name"} =
               ScriptParser.parse_effect("\"npc name\"->enable")
    end

    test "Enable - unquoted subject" do
      assert %{type: :enable, subject: "netch_bull_dead"} =
               ScriptParser.parse_effect("netch_bull_dead->enable")
    end

    test "Disable - quoted subject" do
      assert %{type: :disable, subject: "caius cosades"} =
               ScriptParser.parse_effect("\"caius cosades\"->disable")
    end

    test "Disable - unquoted subject" do
      assert %{type: :disable, subject: "ennbjof"} =
               ScriptParser.parse_effect("ennbjof->disable")
    end

    test "AddSpell - without subject" do
      assert %{type: :add_spell, subject: :self, value: "corprus"} =
               ScriptParser.parse_effect("addspell \"corprus\"")
    end

    test "AddSpell - with player subject" do
      assert %{type: :add_spell, subject: :player, value: "blight disease immunity"} =
               ScriptParser.parse_effect("player->addspell \"blight disease immunity\"")
    end

    test "RemoveSpell - without subject" do
      assert %{type: :remove_spell, subject: :self, value: "ash-chancre"} =
               ScriptParser.parse_effect("removespell \"ash-chancre\"")
    end

    test "RemoveSpell - with player subject" do
      assert %{type: :remove_spell, subject: :player, value: "werewolf blood"} =
               ScriptParser.parse_effect("player->removespell \"werewolf blood\"")
    end

    test "RemoveSpell - unquoted spell" do
      assert %{type: :remove_spell, subject: :player, value: "corprus"} =
               ScriptParser.parse_effect("player->removespell corprus")
    end

    test "ForceGreeting - without subject" do
      assert %{type: :force_greeting, subject: :self} =
               ScriptParser.parse_effect("forcegreeting")
    end

    test "ForceGreeting - with explicit subject" do
      assert %{type: :force_greeting, subject: "ahnia"} =
               ScriptParser.parse_effect("\"ahnia\"->forcegreeting")
    end

    test "Goodbye - ends dialogue" do
      assert %{type: :goodbye} = ScriptParser.parse_effect("goodbye")
    end

    test "SetFight - without subject" do
      assert %{type: :set_fight, subject: :self, value: 100} =
               ScriptParser.parse_effect("setfight 100")
    end

    test "SetFight - with explicit subject" do
      assert %{type: :set_fight, subject: "bolvyn venim", value: 100} =
               ScriptParser.parse_effect("\"bolvyn venim\"->setfight 100")
    end

    test "SetFlee - without subject" do
      assert %{type: :set_flee, subject: :self, value: 20} =
               ScriptParser.parse_effect("setflee 20")
    end

    test "SetAlarm - without subject" do
      assert %{type: :set_alarm, subject: :self, value: 100} =
               ScriptParser.parse_effect("setalarm 100")
    end

    test "SetHello - without subject" do
      assert %{type: :set_hello, subject: :self, value: 0} =
               ScriptParser.parse_effect("sethello 0")
    end

    test "SetHello - with explicit subject" do
      assert %{type: :set_hello, subject: "rolf long-tooth", value: 10} =
               ScriptParser.parse_effect("\"rolf long-tooth\"->sethello 10")
    end

    test "StartScript - unquoted script id" do
      assert %{type: :start_script, script_id: "all_nerevarine"} =
               ScriptParser.parse_effect("startscript all_nerevarine")
    end

    test "StartScript - quoted script id" do
      assert %{type: :start_script, script_id: "vampire_cure_pc"} =
               ScriptParser.parse_effect("startscript \"vampire_cure_pc\"")
    end

    test "StopScript - unquoted script id" do
      assert %{type: :stop_script, script_id: "all_hortator"} =
               ScriptParser.parse_effect("stopscript all_hortator")
    end

    test "StopScript - quoted script id" do
      assert %{type: :stop_script, script_id: "vampire_cure_pc"} =
               ScriptParser.parse_effect("stopscript \"vampire_cure_pc\"")
    end

    test "StartCombat - against player without attacker" do
      assert %{type: :start_combat, subject: :self, value: "player"} =
               ScriptParser.parse_effect("startcombat player")
    end

    test "StartCombat - NPC against player" do
      assert %{type: :start_combat, subject: "bolvyn venim", value: "player"} =
               ScriptParser.parse_effect("\"bolvyn venim\"->startcombat player")
    end

    test "StartCombat - NPC against NPC" do
      assert %{type: :start_combat, subject: "afer flaccus_guard", value: "baslod"} =
               ScriptParser.parse_effect("\"afer flaccus_guard\"->startcombat \"baslod\"")
    end

    test "StopCombat - without subject" do
      assert %{type: :stop_combat, subject: :self} =
               ScriptParser.parse_effect("stopcombat")
    end

    test "StopCombat - with explicit NPC" do
      assert %{type: :stop_combat, subject: "guard"} =
               ScriptParser.parse_effect("\"guard\"->stopcombat")
    end

    test "AIFollow - follow player" do
      assert %{type: :ai_follow, subject: :self, target: :player} =
               ScriptParser.parse_effect("aifollow player 0 0 0 0")
    end

    test "AIFollow - NPC follows player" do
      assert %{type: :ai_follow, subject: "rolf long-tooth", target: :player} =
               ScriptParser.parse_effect("\"rolf long-tooth\"->aifollow player 0 0 0 0 0 0")
    end

    test "AIFollow - NPC follows another NPC" do
      assert %{type: :ai_follow, subject: "rabinna", target: "im_kilaya"} =
               ScriptParser.parse_effect("rabinna->aifollow im_kilaya 128 0 0 0 0 0 0")
    end

    test "AIFollow - quoted follow subject" do
      assert %{type: :ai_follow, subject: :self, target: "galyn arvel"} =
               ScriptParser.parse_effect("aifollow \"galyn arvel\" 0 0 0 0 0")
    end

    test "AITravel - without subject" do
      assert %{type: :ai_travel, subject: :self, target: %{x: 100, y: 200, z: 300}} =
               ScriptParser.parse_effect("aitravel 100 200 300")
    end

    test "AITravel - with explicit subject" do
      assert %{type: :ai_travel, subject: "fargoth", target: %{x: 100, y: 200, z: 300}} =
               ScriptParser.parse_effect("\"fargoth\"->aitravel 100 200 300")
    end

    test "AIWander - without subject" do
      assert %{type: :ai_wander, subject: :self, range: 256} =
               ScriptParser.parse_effect("aiwander 256 0 0 0 0 0 0 0 0 0 0 0")
    end

    test "AIWander - with explicit subject" do
      assert %{type: :ai_wander, subject: "fargoth", range: 512} =
               ScriptParser.parse_effect("\"fargoth\"->aiwander 512 0 0 0 0 0 0 0 0 0 0 0")
    end

    test "AIEscort - escort player" do
      assert %{
               type: :ai_escort,
               subject: :self,
               target: :player,
               duration: 0,
               destination: %{x: 70685, y: 126_106, z: 835}
             } =
               ScriptParser.parse_effect("aiescort player 0 70685 126106 835 0")
    end

    test "AIEscort - NPC escorts player" do
      assert %{
               type: :ai_escort,
               subject: "guard",
               target: :player,
               duration: 0,
               destination: %{x: 100, y: 200, z: 300}
             } =
               ScriptParser.parse_effect("\"guard\"->aiescort player 0 100 200 300 0")
    end

    test "Lock - without subject" do
      assert %{type: :lock, subject: :self, value: 100} =
               ScriptParser.parse_effect("lock 100")
    end

    test "Lock - with explicit subject" do
      assert %{type: :lock, subject: "in_mh_door_01_velas", value: 100} =
               ScriptParser.parse_effect("in_mh_door_01_velas->lock 100")
    end

    test "Lock - with quoted subject" do
      assert %{type: :lock, subject: "ex_mh_door_02_ignatius", value: 40} =
               ScriptParser.parse_effect("\"ex_mh_door_02_ignatius\"->lock 40")
    end

    test "Unlock - without subject" do
      assert %{type: :unlock, subject: :self} =
               ScriptParser.parse_effect("unlock")
    end

    test "Unlock - with explicit subject" do
      assert %{type: :unlock, subject: "in_mh_door_01_velas"} =
               ScriptParser.parse_effect("in_mh_door_01_velas->unlock")
    end

    test "PlaceAtPC - basic" do
      assert %{type: :place_at_pc, value: "skeleton"} =
               ScriptParser.parse_effect("placeatpc \"skeleton\" 1 50 1")
    end

    test "PlaceAtPC - unquoted object" do
      assert %{type: :place_at_pc, value: "skeleton_weak"} =
               ScriptParser.parse_effect("placeatpc skeleton_weak 1 50 1")
    end

    test "PositionCell - basic" do
      assert %{type: :position_cell, subject: :self, value: "balmora"} =
               ScriptParser.parse_effect("positioncell 100 200 300 0 \"balmora\"")
    end

    test "PositionCell - with subject" do
      assert %{type: :position_cell, subject: :player, value: "vivec"} =
               ScriptParser.parse_effect("player->positioncell 100 200 300 0 \"vivec\"")
    end

    test "Mod Stats - modstrength" do
      assert %{type: :mod_strength, subject: :self, value: 10} =
               ScriptParser.parse_effect("modstrength 10")
    end

    test "Mod Stats - modintelligence" do
      assert %{type: :mod_intelligence, subject: :self, value: 5} =
               ScriptParser.parse_effect("modintelligence 5")
    end

    test "Mod Stats - modwillpower" do
      assert %{type: :mod_willpower, subject: :self, value: 5} =
               ScriptParser.parse_effect("modwillpower 5")
    end

    test "Mod Stats - modagility" do
      assert %{type: :mod_agility, subject: :self, value: 5} =
               ScriptParser.parse_effect("modagility 5")
    end

    test "Mod Stats - modspeed" do
      assert %{type: :mod_speed, subject: "dagoth ur", value: 5} =
               ScriptParser.parse_effect("\"dagoth ur\"->modspeed 5")
    end

    test "Mod Stats - modendurance" do
      assert %{type: :mod_endurance, subject: :player, value: 5} =
               ScriptParser.parse_effect("player->modendurance 5")
    end

    test "Mod Stats - modpersonality" do
      assert %{type: :mod_personality, subject: :self, value: 5} =
               ScriptParser.parse_effect("modpersonality 5")
    end

    test "Mod Stats - modluck" do
      assert %{type: :mod_luck, subject: :self, value: 5} =
               ScriptParser.parse_effect("modluck 5")
    end

    test "Mod Stats - negative value" do
      assert %{type: :mod_strength, subject: :self, value: -5} =
               ScriptParser.parse_effect("modstrength -5")
    end

    test "comments" do
      assert nil == ScriptParser.parse_effect(";this is a comment")
    end

    test "control flow" do
      assert nil == ScriptParser.parse_effect("endif")
      assert nil == ScriptParser.parse_effect("else")
    end

    test "random text" do
      assert nil == ScriptParser.parse_effect("return")
    end
  end

  describe "parse_condition" do
    test "GetJournalIndex - basic" do
      assert %{type: :journal_index, target: "MV_SlaveMule", operator: :<=, value: 100} =
               ScriptParser.parse_condition("if ( getjournalindex \"MV_SlaveMule\" <= 100 )")
    end

    test "GetJournalIndex - unquoted quest id" do
      assert %{type: :journal_index, target: "B5_RedoranHort", operator: :>=, value: 50} =
               ScriptParser.parse_condition("if ( getjournalindex B5_RedoranHort >= 50 )")
    end

    test "GetJournalIndex - equals" do
      assert %{type: :journal_index, target: "romance_ahnassi", operator: :==, value: 33} =
               ScriptParser.parse_condition("if ( getjournalindex romance_ahnassi == 33 )")
    end

    test "GetDeadCount - basic" do
      assert %{type: :dead_count, target: "Ahnia", operator: :>, value: 0} =
               ScriptParser.parse_condition("if ( getdeadcount \"Ahnia\" > 0 )")
    end

    test "GetItemCount - basic" do
      assert %{type: :item_count, target: "slave_bracer_left", operator: :>, value: 0} =
               ScriptParser.parse_condition("if ( getitemcount slave_bracer_left > 0 )")
    end

    test "GetItemCount - with subject" do
      assert %{
               type: :item_count,
               subject: :player,
               target: "katana_goldbrand_unique",
               operator: :==,
               value: 1
             } =
               ScriptParser.parse_condition(
                 "if ( player->getitemcount \"katana_goldbrand_unique\" == 1 )"
               )
    end

    test "GetPCCell - quoted cell name" do
      assert %{type: :pc_cell, target: "Ebonheart, Argonian Mission", operator: :==, value: 1} =
               ScriptParser.parse_condition(
                 "if ( getpccell \"Ebonheart, Argonian Mission\" == 1 )"
               )
    end

    test "GetPCCell - without == 1" do
      assert %{type: :pc_cell, target: "vivec, arena", operator: :==, value: 1} =
               ScriptParser.parse_condition("if ( getpccell \"vivec, arena\" )")
    end

    test "OnDeath - basic" do
      assert %{type: :on_death, subject: :self} =
               ScriptParser.parse_condition("if ( ondeath == 1 )")
    end

    test "OnDeath - with subject" do
      assert %{type: :on_death, subject: "netch_giant_unique"} =
               ScriptParser.parse_condition("if ( \"netch_giant_unique\"->ondeath == 1 )")
    end

    test "OnActivate - basic" do
      assert %{type: :on_activate, subject: :self, operator: :==, value: 1} =
               ScriptParser.parse_condition("if ( onactivate == 1 )")
    end

    test "GetDisabled - basic" do
      assert %{type: :disabled, subject: :self, operator: :==, value: 1} =
               ScriptParser.parse_condition("if ( getdisabled == 1 )")
    end

    test "GetDisabled - with subject" do
      assert %{type: :disabled, subject: "itermerel", operator: :==, value: 0} =
               ScriptParser.parse_condition("if ( \"itermerel\"->getdisabled == 0 )")
    end

    test "GetDistance - basic" do
      assert %{type: :distance, subject: :self, target: "player", operator: :<=, value: 256} =
               ScriptParser.parse_condition("if ( getdistance player <= 256 )")
    end

    test "GetDistance - with quoted target" do
      assert %{
               type: :distance,
               subject: :self,
               target: "guar_white_unique",
               operator: :<=,
               value: 256
             } =
               ScriptParser.parse_condition("if ( getdistance \"guar_white_unique\" <= 256 )")
    end

    test "GetDistance - with <==" do
      # plantScript wtf
      assert %{type: :distance, subject: :self, target: "player", operator: :<=, value: 512} =
               ScriptParser.parse_condition("if ( getdistance player <== 512 )")
    end

    test "GetHealth - basic" do
      assert %{type: :health, subject: :self, operator: :>, value: 0} =
               ScriptParser.parse_condition("if ( gethealth > 0 )")
    end

    test "GetHealth - less than or equal" do
      assert %{type: :health, subject: :self, operator: :<=, value: 0} =
               ScriptParser.parse_condition("if ( gethealth <= 0 )")
    end

    test "GetHealth - variable" do
      assert %{type: :health, subject: :player, operator: :<=, value: "halfhealth"} =
               ScriptParser.parse_condition("if ( player->gethealth <= halfhealth )")
    end

    test "GetHealth - no spaces" do
      assert %{type: :health, subject: "Black Dart Malar", operator: :<, value: 1} =
               ScriptParser.parse_condition("if ( \"Black Dart Malar\"->gethealth<1 )")
    end

    test "GetPCRank - basic" do
      assert %{type: :pc_rank, target: "redoran", operator: :==, value: -1} =
               ScriptParser.parse_condition("if ( getpcrank \"redoran\" == -1 )")
    end

    test "GetSpell - basic" do
      assert %{
               type: :knows_spell,
               subject: :player,
               target: "levitate",
               operator: :==,
               value: 1
             } =
               ScriptParser.parse_condition("if ( player->getspell \"levitate\" == 1 )")
    end

    test "GetBlightDisease - basic" do
      assert %{type: :blight_disease, subject: :self, operator: :==, value: 0} =
               ScriptParser.parse_condition("if ( getblightdisease == 0 )")
    end

    test "GetBlightDisease - with subject" do
      assert %{type: :blight_disease, subject: "kwama queen_abaesen", operator: :==, value: 1} =
               ScriptParser.parse_condition(
                 "if ( \"kwama queen_abaesen\"->getblightdisease == 1 )"
               )
    end

    test "GetCommonDisease - basic" do
      assert %{type: :common_disease, subject: :self, operator: :==, value: 0} =
               ScriptParser.parse_condition("if ( getcommondisease == 0 )")
    end

    test "GetCurrentAIPackage - basic" do
      assert %{type: :current_ai_package, subject: :self, operator: :==, value: 3} =
               ScriptParser.parse_condition("if ( getcurrentaipackage == 3 )")
    end

    test "GetCurrentAIPackage - with subject" do
      assert %{
               type: :current_ai_package,
               subject: "guar_llovyn_unique",
               operator: :==,
               value: 3
             } =
               ScriptParser.parse_condition(
                 "if ( \"guar_llovyn_unique\"->getcurrentaipackage == 3 )"
               )
    end

    test "MenuMode - basic" do
      assert %{type: :menu_mode, operator: :==, value: 1} =
               ScriptParser.parse_condition("if ( menumode == 1 )")
    end

    test "CellChanged - basic" do
      assert %{type: :cell_changed, subject: :self, operator: :==, value: 0} =
               ScriptParser.parse_condition("if ( cellchanged == 0 )")
    end

    test "CellChanged - no comparison" do
      assert %{type: :cell_changed, subject: :self} =
               ScriptParser.parse_condition("if ( cellchanged )")
    end

    test "IsWerewolf - basic" do
      assert %{type: :is_werewolf, subject: :self} =
               ScriptParser.parse_condition("if ( iswerewolf == 1 )")
    end

    test "GetRace - basic" do
      assert %{type: :race, subject: :player, target: "dark elf", operator: :==, value: 1} =
               ScriptParser.parse_condition("if ( player->getrace \"dark elf\" == 1 )")
    end

    test "HasSoulGem - basic" do
      assert %{
               type: :has_soul_gem,
               subject: :player,
               target: "golden saint",
               operator: :>,
               value: 0
             } =
               ScriptParser.parse_condition("if ( player->hassoulgem \"golden saint\" > 0 )")
    end

    test "GetLocked - basic" do
      assert %{type: :locked, subject: :self} =
               ScriptParser.parse_condition("if ( getlocked == 1 )")
    end

    test "ScriptRunning - basic" do
      assert %{type: :script_running, target: "myquest", operator: :==, value: 1} =
               ScriptParser.parse_condition("if ( scriptrunning myquest )")
    end

    test "PCExpelled - basic" do
      assert %{type: :expelled, target: "mages guild"} =
               ScriptParser.parse_condition("if ( pcexpelled \"mages guild\" )")
    end

    test "GetAttacked - basic" do
      assert %{type: :attacked, subject: :self} =
               ScriptParser.parse_condition("if ( getattacked == 1 )")
    end

    test "GetAttacked - with subject" do
      assert %{type: :attacked, subject: "yagrum bagarn"} =
               ScriptParser.parse_condition("if ( \"yagrum bagarn\"->getattacked == 1 )")
    end

    # DaysPassed and GameHour
    test "DaysPassed - basic" do
      assert %{type: :days_passed, operator: :>, value: 10} =
               ScriptParser.parse_condition("if ( dayspassed > 10 )")
    end

    test "DaysPassed - equals" do
      assert %{type: :days_passed, operator: :==, value: 0} =
               ScriptParser.parse_condition("if ( dayspassed == 0 )")
    end

    test "GameHour - greater than or equal" do
      assert %{type: :game_hour, operator: :>=, value: 9} =
               ScriptParser.parse_condition("if ( gamehour >= 9 )")
    end

    test "GameHour - less than" do
      assert %{type: :game_hour, operator: :<, value: 22} =
               ScriptParser.parse_condition("if ( gamehour < 22 )")
    end

    # GetAIPackageDone
    test "GetAIPackageDone - basic" do
      assert %{type: :ai_package_done, subject: :self, operator: :==, value: 1} =
               ScriptParser.parse_condition("if ( getaipackagedone == 1 )")
    end

    test "GetAIPackageDone - with subject" do
      assert %{type: :ai_package_done, subject: "fargoth", operator: :==, value: 1} =
               ScriptParser.parse_condition("if ( fargoth->getaipackagedone == 1 )")
    end

    # GetButtonPressed
    test "GetButtonPressed - basic" do
      assert %{type: :button_pressed, operator: :!=, value: -1} =
               ScriptParser.parse_condition("if ( getbuttonpressed != -1 )")
    end

    # GetCollidingPC / GetCollidingActor
    test "GetCollidingPC - basic" do
      assert %{type: :colliding_pc, subject: :self} =
               ScriptParser.parse_condition("if ( getcollidingpc == 1 )")
    end

    test "GetCollidingPC - no comparison" do
      assert %{type: :colliding_pc, subject: :self} =
               ScriptParser.parse_condition("if ( getcollidingpc )")
    end

    test "GetCollidingActor - no comparison" do
      assert %{type: :colliding_actor, subject: :self} =
               ScriptParser.parse_condition("if ( getcollidingactor )")
    end

    # GetCurrentWeather
    test "GetCurrentWeather - basic" do
      assert %{type: :current_weather, operator: :>=, value: 5} =
               ScriptParser.parse_condition("if ( getcurrentweather >= 5 )")
    end

    # GetDetected
    test "GetDetected - basic" do
      assert %{type: :detected, subject: :self, target: "player", operator: :==, value: 1} =
               ScriptParser.parse_condition("if ( getdetected player == 1 )")
    end

    test "GetDetected - with subject and quoted target" do
      assert %{type: :detected, subject: "jeanne", target: "player", operator: :==, value: 1} =
               ScriptParser.parse_condition("if ( jeanne->getdetected player == 1 )")
    end

    # GetDisposition
    test "GetDisposition - with subject" do
      assert %{type: :disposition, subject: "huleeya", operator: :>, value: 50} =
               ScriptParser.parse_condition("if ( huleeya->getdisposition > 50 )")
    end

    # GetEffect
    test "GetEffect - basic" do
      assert %{
               type: :effect,
               subject: :self,
               target: "seffectinvisibility",
               operator: :==,
               value: 1
             } =
               ScriptParser.parse_condition("if ( geteffect seffectinvisibility == 1 )")
    end

    test "GetEffect - with subject" do
      assert %{type: :effect, subject: :player, target: "seffectpoison", operator: :==, value: 1} =
               ScriptParser.parse_condition("if ( player->geteffect seffectpoison == 1 )")
    end

    # GetFatigue / GetMagicka
    test "GetFatigue - basic" do
      assert %{type: :fatigue, subject: :self, operator: :<, value: 1} =
               ScriptParser.parse_condition("if ( getfatigue < 1 )")
    end

    test "GetMagicka - basic" do
      assert %{type: :magicka, subject: :self, operator: :>, value: 0} =
               ScriptParser.parse_condition("if ( getmagicka > 0 )")
    end

    # GetLevel
    test "GetLevel - basic" do
      assert %{type: :level, subject: :player, operator: :>=, value: 30} =
               ScriptParser.parse_condition("if ( player->getlevel >= 30 )")
    end

    # GetLOS (line of sight)
    test "GetLOS - basic" do
      assert %{type: :line_of_sight, subject: :self, target: "player", operator: :==, value: 1} =
               ScriptParser.parse_condition("if ( getlos player == 1 )")
    end

    # GetPos
    test "GetPos - basic" do
      assert %{type: :position, subject: :self, target: "y", operator: :>, value: 1730} =
               ScriptParser.parse_condition("if ( getpos y > 1730 )")
    end

    test "GetPos - with subject" do
      assert %{
               type: :position,
               subject: "sharn gra-muzgob",
               target: "z",
               operator: :<,
               value: -1000
             } =
               ScriptParser.parse_condition("if ( \"sharn gra-muzgob\"->getpos z < -1000 )")
    end

    # GetSoundPlaying
    test "GetSoundPlaying - basic" do
      assert %{type: :sound_playing, subject: :self, target: "sound_id", operator: :==, value: 1} =
               ScriptParser.parse_condition("if ( getsoundplaying \"sound_id\" == 1 )")
    end

    # GetStandingPC / GetStandingActor
    test "GetStandingPC - basic" do
      assert %{type: :standing_pc, subject: :self, operator: :==, value: 1} =
               ScriptParser.parse_condition("if ( getstandingpc == 1 )")
    end

    test "GetStandingActor - basic" do
      assert %{type: :standing_actor, subject: :self, operator: :==, value: 1} =
               ScriptParser.parse_condition("if ( getstandingactor == 1 )")
    end

    # GetTarget
    test "GetTarget - basic" do
      assert %{type: :target, subject: :self, target: "player", operator: :==, value: 1} =
               ScriptParser.parse_condition("if ( gettarget player == 1 )")
    end

    test "GetTarget - with subject" do
      assert %{type: :target, subject: "someone", target: "player", operator: :==, value: 1} =
               ScriptParser.parse_condition("if ( \"someone\"->gettarget player == 1 )")
    end

    # GetWaterLevel
    test "GetWaterLevel - basic" do
      assert %{type: :water_level, subject: :self, operator: :!=, value: -875} =
               ScriptParser.parse_condition("if ( getwaterlevel != -875 )")
    end

    # GetWeaponDrawn
    test "GetWeaponDrawn - basic" do
      assert %{type: :weapon_drawn, subject: :player, operator: :==, value: 0} =
               ScriptParser.parse_condition("if ( player->getweapondrawn == 0 )")
    end

    # GetWerewolfKills
    test "GetWerewolfKills - basic" do
      assert %{type: :werewolf_kills, operator: :==, value: 0} =
               ScriptParser.parse_condition("if ( getwerewolfkills == 0 )")
    end

    # HasItemEquipped
    test "HasItemEquipped - basic" do
      assert %{
               type: :has_item_equipped,
               subject: :player,
               target: "steel saber_elberoth",
               operator: :==,
               value: 1
             } =
               ScriptParser.parse_condition(
                 "if ( player->hasitemequipped \"steel saber_elberoth\" == 1 )"
               )
    end

    # OnKnockout
    test "OnKnockout - basic" do
      assert %{type: :on_knockout, subject: :self} =
               ScriptParser.parse_condition("if ( onknockout == 1 )")
    end

    # OnMurder
    test "OnMurder - basic" do
      assert %{type: :on_murder, subject: :self} =
               ScriptParser.parse_condition("if ( onmurder == 1 )")
    end

    # OnPCEquip
    test "OnPCEquip - basic" do
      assert %{type: :on_pc_equip, subject: :self, operator: :==, value: 1} =
               ScriptParser.parse_condition("if ( onpcequip == 1 )")
    end

    test "OnPCEquip - not equal" do
      assert %{type: :on_pc_equip, subject: :self, operator: :!=, value: 1} =
               ScriptParser.parse_condition("if ( onpcequip != 1 )")
    end

    # OnPCHitMe
    test "OnPCHitMe - basic" do
      assert %{type: :on_pc_hit_me, subject: :self} =
               ScriptParser.parse_condition("if ( onpchitme == 1 )")
    end

    # Random
    test "Random - basic" do
      assert %{type: :random, target: 100, operator: :>, value: 50} =
               ScriptParser.parse_condition("if ( random 100 > 50 )")
    end

    # SayDone
    test "SayDone - basic" do
      assert %{type: :say_done, subject: :self, operator: :==, value: 1} =
               ScriptParser.parse_condition("if ( saydone == 1 )")
    end

    test "SayDone - with subject" do
      assert %{type: :say_done, subject: :player, operator: :==, value: 1} =
               ScriptParser.parse_condition("if ( player->saydone == 1 )")
    end

    # GetInterior
    test "GetInterior - no comparison" do
      assert %{type: :interior, subject: :self} =
               ScriptParser.parse_condition("if ( getinterior )")
    end

    # Format variations
    test "Subject with space before arrow" do
      assert %{type: :disabled, subject: "duma gro-lag2", operator: :==, value: 1} =
               ScriptParser.parse_condition("if ( \"duma gro-lag2\"-> getdisabled == 1 )")
    end

    test "No spaces around operator" do
      assert %{type: :level, subject: :player, operator: :>=, value: 20} =
               ScriptParser.parse_condition("if ( player->getlevel >=20 )")
    end

    test "GetPCCell - not in cell" do
      assert %{type: :pc_cell, target: "abernanit", operator: :==, value: 0} =
               ScriptParser.parse_condition("if ( getpccell \"abernanit\" == 0 )")
    end

    test "Local variable - basic" do
      assert %{type: :local_var, target: "doonce", operator: :==, value: 0} =
               ScriptParser.parse_condition("if ( doonce == 0 )", ["doonce"])
    end

    test "Local variable - greater than" do
      assert %{type: :local_var, target: "state", operator: :>, value: 1} =
               ScriptParser.parse_condition("if ( state > 1 )", ["state"])
    end

    test "Local variable - overlapping name" do
      assert %{type: :local_var, target: "randomized", operator: :==, value: 0} =
               ScriptParser.parse_condition("if ( randomized == 0 )", ["randomized"])
    end

    test "returns nil for non-condition" do
      assert nil == ScriptParser.parse_condition("Journal Quest 50")
      assert nil == ScriptParser.parse_condition("AddItem gold 100")
    end
  end
end
