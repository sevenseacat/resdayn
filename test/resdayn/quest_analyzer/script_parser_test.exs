defmodule Resdayn.QuestAnalyzer.ScriptParserTest do
  use ExUnit.Case, async: true

  alias Resdayn.QuestAnalyzer.ScriptParser

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
      expected = %ScriptParser.AST{
        name: nil,
        locals: [],
        body: [
          %ScriptParser.Journal{quest_id: "mv_deadtaxman", index: 100},
          %ScriptParser.Effect{
            function: :remove_item,
            data: %{subject: :self, item_id: "gold_001", count: 500}
          },
          %ScriptParser.Effect{
            function: :add_item,
            data: %{subject: :player, item_id: "gold_001", count: 500}
          },
          %ScriptParser.Effect{function: :goodbye, data: %{}}
        ]
      }

      assert ScriptParser.parse(@script_simple) == expected
    end

    test "script with single condition" do
      expected = %ScriptParser.AST{
        name: nil,
        locals: [],
        body: [
          %ScriptParser.IfBlock{
            condition: %{
              left: %{function: :journal_index, arg: "mv_slavemule"},
              operator: :<=,
              right: %{value: 100}
            },
            body: [
              %ScriptParser.Journal{quest_id: "mv_slavemule", index: 101}
            ],
            else_clause: nil
          }
        ]
      }

      assert ScriptParser.parse(@script_single_condition) == expected
    end

    test "script with else" do
      expected = %ScriptParser.AST{
        name: nil,
        locals: [],
        body: [
          %ScriptParser.IfBlock{
            condition: %{
              left: %{function: :journal_index, arg: "quest"},
              operator: :==,
              right: %{value: 10}
            },
            body: [
              %ScriptParser.Journal{quest_id: "quest", index: 20}
            ],
            else_clause: [
              %ScriptParser.Journal{quest_id: "quest", index: 30}
            ]
          }
        ]
      }

      assert ScriptParser.parse(@script_else) == expected
    end

    test "script with elseif" do
      expected = %ScriptParser.AST{
        name: nil,
        locals: [],
        body: [
          %ScriptParser.IfBlock{
            condition: %{
              left: %{function: :journal_index, arg: "mv_slavemule"},
              operator: :<=,
              right: %{value: 100}
            },
            body: [
              %ScriptParser.Journal{quest_id: "mv_slavemule", index: 101}
            ],
            else_clause: %ScriptParser.IfBlock{
              condition: %{
                left: %{function: :journal_index, arg: "mv_slavemule"},
                operator: :==,
                right: %{value: 102}
              },
              body: [
                %ScriptParser.Journal{quest_id: "mv_slavemule", index: 103}
              ],
              else_clause: nil
            }
          }
        ]
      }

      assert ScriptParser.parse(@script_elseif) == expected
    end

    test "script with nested conditions" do
      expected = %ScriptParser.AST{
        name: nil,
        locals: [],
        body: [
          %ScriptParser.IfBlock{
            condition: %{
              left: %{function: :journal_index, arg: "b5_redoranhort"},
              operator: :>=,
              right: %{value: 50}
            },
            body: [
              %ScriptParser.IfBlock{
                condition: %{
                  left: %{function: :journal_index, arg: "b6_hlaaluhort"},
                  operator: :>=,
                  right: %{value: 50}
                },
                body: [
                  %ScriptParser.IfBlock{
                    condition: %{
                      left: %{function: :journal_index, arg: "b7_telvannihort"},
                      operator: :>=,
                      right: %{value: 50}
                    },
                    body: [
                      %ScriptParser.Journal{quest_id: "b8_all_hortator", index: 50}
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
      expected = %ScriptParser.AST{
        name: nil,
        locals: [],
        body: [
          %ScriptParser.IfBlock{
            condition: %{
              left: %{function: :dead_count, arg: "ahnia"},
              operator: :>,
              right: %{value: 0}
            },
            body: [
              %ScriptParser.IfBlock{
                condition: %{
                  left: %{function: :journal_index, arg: "ms_scrollsales"},
                  operator: :>,
                  right: %{value: 0}
                },
                body: [
                  %ScriptParser.IfBlock{
                    condition: %{
                      left: %{function: :journal_index, arg: "ms_scrollsales"},
                      operator: :<,
                      right: %{value: 40}
                    },
                    body: [
                      %ScriptParser.Journal{quest_id: "ms_scrollsales", index: 40}
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
      expected = %ScriptParser.AST{
        name: nil,
        locals: [],
        body: [
          %ScriptParser.IfBlock{
            condition: %{
              left: %{function: :journal_index, arg: "c3_destroydagoth"},
              operator: :==,
              right: %{value: 20}
            },
            body: [
              %ScriptParser.Journal{quest_id: "c3_destroydagoth", index: 50},
              %ScriptParser.Journal{quest_id: "a1_sleepersawake", index: 50}
            ],
            else_clause: nil
          }
        ]
      }

      assert ScriptParser.parse(@script_multiple_quests) == expected
    end

    test "script with effects before journal" do
      expected = %ScriptParser.AST{
        name: nil,
        locals: [],
        body: [
          %ScriptParser.IfBlock{
            condition: %{
              left: %{function: :journal_index, arg: "mv_slavemule"},
              operator: :<=,
              right: %{value: 100}
            },
            body: [
              %ScriptParser.Effect{
                function: :add_item,
                data: %{subject: :self, item_id: "ingred_moon_sugar_01", count: 20}
              },
              %ScriptParser.Journal{quest_id: "mv_slavemule", index: 101}
            ],
            else_clause: nil
          }
        ]
      }

      assert ScriptParser.parse(@script_effects_before_journal) == expected
    end

    test "script with effects before and after journal" do
      expected = %ScriptParser.AST{
        name: nil,
        locals: [],
        body: [
          %ScriptParser.IfBlock{
            condition: %{
              left: %{function: :journal_index, arg: "mv_slavemule"},
              operator: :<=,
              right: %{value: 100}
            },
            body: [
              %ScriptParser.Effect{
                function: :add_item,
                data: %{subject: :self, item_id: "ingred_moon_sugar_01", count: 20}
              },
              %ScriptParser.Journal{quest_id: "mv_slavemule", index: 101},
              %ScriptParser.Effect{function: :mod_disposition, data: %{subject: :self, value: 15}}
            ],
            else_clause: nil
          }
        ]
      }

      assert ScriptParser.parse(@script_effects_before_and_after) == expected
    end

    test "script with shared effects" do
      expected = %ScriptParser.AST{
        name: nil,
        locals: [],
        body: [
          %ScriptParser.IfBlock{
            condition: %{
              left: %{function: :journal_index, arg: "c3_destroydagoth"},
              operator: :==,
              right: %{value: 20}
            },
            body: [
              %ScriptParser.Effect{function: :enable, data: %{subject: "ring of azura"}},
              %ScriptParser.Journal{quest_id: "c3_destroydagoth", index: 50},
              %ScriptParser.Journal{quest_id: "a1_sleepersawake", index: 50},
              %ScriptParser.Effect{function: :mod_reputation, data: %{subject: :self, value: 10}}
            ],
            else_clause: nil
          }
        ]
      }

      assert ScriptParser.parse(@script_shared_effects) == expected
    end

    test "script with different blocks" do
      expected = %ScriptParser.AST{
        name: nil,
        locals: [],
        body: [
          %ScriptParser.IfBlock{
            condition: %{
              left: %{function: :journal_index, arg: "quest"},
              operator: :<,
              right: %{value: 50}
            },
            body: [
              %ScriptParser.Effect{
                function: :add_item,
                data: %{subject: :self, item_id: "reward1", count: 1}
              },
              %ScriptParser.Journal{quest_id: "quest", index: 50}
            ],
            else_clause: nil
          },
          %ScriptParser.IfBlock{
            condition: %{
              left: %{function: :journal_index, arg: "quest"},
              operator: :>=,
              right: %{value: 50}
            },
            body: [
              %ScriptParser.Effect{
                function: :add_item,
                data: %{subject: :self, item_id: "reward2", count: 1}
              },
              %ScriptParser.Journal{quest_id: "quest", index: 100}
            ],
            else_clause: nil
          }
        ]
      }

      assert ScriptParser.parse(@script_different_blocks) == expected
    end

    test "script with PCCell condition (and supports)" do
      expected = %ScriptParser.AST{
        name: "scriptpccellcondition",
        locals: ["currentcell", "longtimeago"],
        body: [
          %ScriptParser.IfBlock{
            condition: %{
              left: %{function: :current_cell, arg: "ebonheart, argonian mission"},
              operator: :==,
              right: %{value: 1}
            },
            body: [
              %ScriptParser.Journal{quest_id: "mv_slavemule", index: 114}
            ],
            else_clause: nil
          }
        ]
      }

      assert ScriptParser.parse(@script_pc_cell_condition) == expected
    end

    test "script with OnDeath condition" do
      expected = %ScriptParser.AST{
        name: nil,
        locals: [],
        body: [
          %ScriptParser.IfBlock{
            condition: %{
              left: %{function: :on_death, subject: :self},
              operator: :==,
              right: %{value: 1}
            },
            body: [
              %ScriptParser.Journal{quest_id: "somequest", index: 50}
            ],
            else_clause: nil
          }
        ]
      }

      assert ScriptParser.parse(@script_on_death_condition) == expected
    end

    test "script with hierarchical conditions" do
      expected = %ScriptParser.AST{
        name: nil,
        locals: [],
        body: [
          %ScriptParser.IfBlock{
            condition: %{
              left: %{function: :journal_index, arg: "mainquest"},
              operator: :>=,
              right: %{value: 10}
            },
            body: [
              %ScriptParser.Effect{function: :add_topic, data: %{topic_id: "rumors"}},
              %ScriptParser.IfBlock{
                condition: %{
                  left: %{function: :dead_count, arg: "villain"},
                  operator: :>=,
                  right: %{value: 1}
                },
                body: [
                  %ScriptParser.Effect{
                    function: :add_item,
                    data: %{subject: :player, item_id: "gold_001", count: 500}
                  },
                  %ScriptParser.Journal{quest_id: "mainquest", index: 20},
                  %ScriptParser.IfBlock{
                    condition: %{
                      left: %{function: :item_count, subject: :self, arg: "secret_note"},
                      operator: :>=,
                      right: %{value: 1}
                    },
                    body: [
                      %ScriptParser.Journal{quest_id: "sidequest", index: 10},
                      %ScriptParser.Effect{function: :add_topic, data: %{topic_id: "secret"}}
                    ],
                    else_clause: nil
                  },
                  %ScriptParser.Effect{
                    function: :mod_faction_reputation,
                    data: %{faction_id: "fighters guild", value: 5}
                  },
                  %ScriptParser.Journal{quest_id: "mainquest", index: 30}
                ],
                else_clause: nil
              },
              %ScriptParser.Journal{quest_id: "mainquest", index: 15}
            ],
            else_clause: nil
          }
        ]
      }

      assert ScriptParser.parse(@script_hierarchical_levels) == expected
    end

    test "script with start script" do
      expected = %ScriptParser.AST{
        name: nil,
        locals: [],
        body: [
          %ScriptParser.Journal{quest_id: "quest", index: 20},
          %ScriptParser.Effect{function: :start_script, data: %{script_id: "otherscript"}}
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
                   %{function: :remove_item, subject: :self, item_id: "gold_001", count: 500},
                   %{function: :add_item, subject: :player, item_id: "gold_001", count: 500},
                   %{function: :goodbye}
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
                     left: %{function: :journal_index, arg: "mv_slavemule"},
                     operator: :<=,
                     right: %{value: 100}
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
                     left: %{function: :journal_index, arg: "mv_slavemule"},
                     operator: :<=,
                     right: %{value: 100}
                   }
                 ]
               },
               %{
                 quest_id: "mv_slavemule",
                 index: 103,
                 effects: [],
                 conditions: [
                   %{
                     left: %{function: :journal_index, arg: "mv_slavemule"},
                     operator: :==,
                     right: %{value: 102}
                   }
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
                   %{
                     left: %{function: :journal_index, arg: "b5_redoranhort"},
                     operator: :>=,
                     right: %{value: 50}
                   },
                   %{
                     left: %{function: :journal_index, arg: "b6_hlaaluhort"},
                     operator: :>=,
                     right: %{value: 50}
                   },
                   %{
                     left: %{function: :journal_index, arg: "b7_telvannihort"},
                     operator: :>=,
                     right: %{value: 50}
                   }
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
                   %{
                     left: %{function: :dead_count, arg: "ahnia"},
                     operator: :>,
                     right: %{value: 0}
                   },
                   %{
                     left: %{function: :journal_index, arg: "ms_scrollsales"},
                     operator: :>,
                     right: %{value: 0}
                   },
                   %{
                     left: %{function: :journal_index, arg: "ms_scrollsales"},
                     operator: :<,
                     right: %{value: 40}
                   }
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
                   %{
                     left: %{function: :journal_index, arg: "c3_destroydagoth"},
                     operator: :==,
                     right: %{value: 20}
                   }
                 ]
               },
               %{
                 quest_id: "a1_sleepersawake",
                 index: 50,
                 effects: [],
                 conditions: [
                   %{
                     left: %{function: :journal_index, arg: "c3_destroydagoth"},
                     operator: :==,
                     right: %{value: 20}
                   }
                 ]
               }
             ]
    end

    test "script with effects before journal command" do
      actual = ScriptParser.extract_journal_commands(@script_effects_before_journal)

      assert actual == [
               %{
                 quest_id: "mv_slavemule",
                 index: 101,
                 effects: [
                   %{
                     function: :add_item,
                     subject: :self,
                     item_id: "ingred_moon_sugar_01",
                     count: 20
                   }
                 ],
                 conditions: [
                   %{
                     left: %{function: :journal_index, arg: "mv_slavemule"},
                     operator: :<=,
                     right: %{value: 100}
                   }
                 ]
               }
             ]
    end

    test "script with effects before and after journal command" do
      actual = ScriptParser.extract_journal_commands(@script_effects_before_and_after)

      assert actual == [
               %{
                 quest_id: "mv_slavemule",
                 index: 101,
                 effects: [
                   %{
                     function: :add_item,
                     subject: :self,
                     item_id: "ingred_moon_sugar_01",
                     count: 20
                   },
                   %{function: :mod_disposition, subject: :self, value: 15}
                 ],
                 conditions: [
                   %{
                     left: %{function: :journal_index, arg: "mv_slavemule"},
                     operator: :<=,
                     right: %{value: 100}
                   }
                 ]
               }
             ]
    end

    test "script with multiple quests shares block effects" do
      actual = ScriptParser.extract_journal_commands(@script_shared_effects)

      # Both journals get all effects from the block
      assert actual == [
               %{
                 quest_id: "c3_destroydagoth",
                 index: 50,
                 effects: [
                   %{function: :enable, subject: "ring of azura"},
                   %{function: :mod_reputation, value: 10, subject: :self}
                 ],
                 conditions: [
                   %{
                     left: %{function: :journal_index, arg: "c3_destroydagoth"},
                     operator: :==,
                     right: %{value: 20}
                   }
                 ]
               },
               %{
                 quest_id: "a1_sleepersawake",
                 index: 50,
                 effects: [
                   %{function: :enable, subject: "ring of azura"},
                   %{function: :mod_reputation, value: 10, subject: :self}
                 ],
                 conditions: [
                   %{
                     left: %{function: :journal_index, arg: "c3_destroydagoth"},
                     operator: :==,
                     right: %{value: 20}
                   }
                 ]
               }
             ]
    end

    test "different blocks have different effects" do
      actual = ScriptParser.extract_journal_commands(@script_different_blocks)

      assert actual == [
               %{
                 quest_id: "quest",
                 index: 50,
                 effects: [%{function: :add_item, subject: :self, item_id: "reward1", count: 1}],
                 conditions: [
                   %{
                     left: %{function: :journal_index, arg: "quest"},
                     operator: :<,
                     right: %{value: 50}
                   }
                 ]
               },
               %{
                 quest_id: "quest",
                 index: 100,
                 effects: [%{function: :add_item, subject: :self, item_id: "reward2", count: 1}],
                 conditions: [
                   %{
                     left: %{function: :journal_index, arg: "quest"},
                     operator: :>=,
                     right: %{value: 50}
                   }
                 ]
               }
             ]
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
                     left: %{function: :current_cell, arg: "ebonheart, argonian mission"},
                     operator: :==,
                     right: %{value: 1}
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
                 conditions: [
                   %{
                     left: %{function: :on_death, subject: :self},
                     operator: :==,
                     right: %{value: 1}
                   }
                 ]
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
                     %{
                       left: %{function: :journal_index, arg: "mainquest"},
                       operator: :>=,
                       right: %{value: 10}
                     },
                     %{
                       left: %{function: :dead_count, arg: "villain"},
                       operator: :>=,
                       right: %{value: 1}
                     }
                   ],
                   effects: [
                     %{function: :add_topic, topic_id: "rumors"},
                     %{function: :add_item, subject: :player, item_id: "gold_001", count: 500},
                     %{function: :mod_faction_reputation, faction_id: "fighters guild", value: 5}
                   ]
                 },
                 # SideQuest 10: gets all sibling effects from every enclosing scope
                 # (position-independent — including the mod_faction_reputation that
                 # appears in the intermediate scope AFTER the inner block).
                 %{
                   quest_id: "sidequest",
                   index: 10,
                   conditions: [
                     %{
                       left: %{function: :journal_index, arg: "mainquest"},
                       operator: :>=,
                       right: %{value: 10}
                     },
                     %{
                       left: %{function: :dead_count, arg: "villain"},
                       operator: :>=,
                       right: %{value: 1}
                     },
                     %{
                       left: %{function: :item_count, subject: :self, arg: "secret_note"},
                       operator: :>=,
                       right: %{value: 1}
                     }
                   ],
                   effects: [
                     %{function: :add_topic, topic_id: "rumors"},
                     %{function: :add_item, subject: :player, item_id: "gold_001", count: 500},
                     %{function: :mod_faction_reputation, faction_id: "fighters guild", value: 5},
                     %{function: :add_topic, topic_id: "secret"}
                   ]
                 },
                 # MainQuest 30: gets effects from its block level
                 %{
                   quest_id: "mainquest",
                   index: 30,
                   conditions: [
                     %{
                       left: %{function: :journal_index, arg: "mainquest"},
                       operator: :>=,
                       right: %{value: 10}
                     },
                     %{
                       left: %{function: :dead_count, arg: "villain"},
                       operator: :>=,
                       right: %{value: 1}
                     }
                   ],
                   effects: [
                     %{function: :add_topic, topic_id: "rumors"},
                     %{function: :add_item, subject: :player, item_id: "gold_001", count: 500},
                     %{function: :mod_faction_reputation, faction_id: "fighters guild", value: 5}
                   ]
                 },
                 # MainQuest 15: only outer block condition and effects
                 %{
                   quest_id: "mainquest",
                   index: 15,
                   conditions: [
                     %{
                       left: %{function: :journal_index, arg: "mainquest"},
                       operator: :>=,
                       right: %{value: 10}
                     }
                   ],
                   effects: [
                     %{function: :add_topic, topic_id: "rumors"}
                   ]
                 }
               ])
    end

    test "secondary scripts started with StartScript are followed" do
      main_script = """
      Journal "TG_LootAldruhnMG" 10
      StartScript "TG_LootMG"
      """

      helper_script = """
      Begin TG_LootMG

      "Erranil"->Disable
      "Movis Darys"->Disable
      "Edwinna Elbert"->Disable

      stopScript TG_LootMG

      End
      """

      expected =
        ScriptParser.extract_journal_commands(
          main_script,
          %{"tg_lootmg" => helper_script},
          follow_scripts: true
        )

      assert expected == [
               %{
                 index: 10,
                 quest_id: "tg_lootaldruhnmg",
                 conditions: [],
                 effects: [
                   %{function: :disable, subject: "erranil"},
                   %{function: :disable, subject: "movis darys"},
                   %{function: :disable, subject: "edwinna elbert"}
                 ]
               }
             ]
    end
  end

  describe "extract_journal_commands — walker effect attribution" do
    # Targeted regression coverage for 7CC-89. The broader hierarchical test
    # above also exercises this, but these minimal cases isolate the rule.
    test "same-scope effects attach position-independently (baseline)" do
      script = """
      AddSpell "spell_before"
      Journal "q" 10
      AddSpell "spell_after"
      """

      assert ScriptParser.extract_journal_commands(script) == [
               %{
                 quest_id: "q",
                 index: 10,
                 conditions: [],
                 effects: [
                   %{function: :add_spell, value: "spell_before", subject: :self},
                   %{function: :add_spell, value: "spell_after", subject: :self}
                 ]
               }
             ]
    end

    test "a journal in a nested if-block sees outer-scope effects regardless of position" do
      script = """
      AddSpell "spell_before"
      if ( SomeCondition == 1 )
        Journal "q" 10
      endif
      AddSpell "spell_after"
      """

      assert ScriptParser.extract_journal_commands(script) == [
               %{
                 quest_id: "q",
                 index: 10,
                 conditions: [
                   %{
                     left: %{local_var: "somecondition"},
                     operator: :==,
                     right: %{value: 1}
                   }
                 ],
                 effects: [
                   %{function: :add_spell, value: "spell_before", subject: :self},
                   %{function: :add_spell, value: "spell_after", subject: :self}
                 ]
               }
             ]
    end

    test "a journal nested two levels deep sees sibling effects from each enclosing scope" do
      # Pattern matches the Sky_qRe_KG4_Vampire reproducer: journal in the
      # innermost block; effects in the intermediate scope before AND after
      # the innermost block both attach.
      script = """
      if ( OuterCondition == 1 )
        AddSpell "outer_before"
        if ( InnerCondition == 1 )
          Journal "q" 10
        endif
        AddSpell "outer_after"
      endif
      """

      [command] = ScriptParser.extract_journal_commands(script)

      assert command.quest_id == "q"
      assert command.index == 10

      assert command.effects == [
               %{function: :add_spell, value: "outer_before", subject: :self},
               %{function: :add_spell, value: "outer_after", subject: :self}
             ]
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

    test "comma-separated syntax" do
      assert {"A1_1_FindSpymaster", 14} =
               ScriptParser.parse_journal_command("journal, \"A1_1_FindSpymaster\", 14")
    end

    test "comma-separated with unquoted quest ID" do
      assert {"MV_SlaveMule", 100} =
               ScriptParser.parse_journal_command("journal, MV_SlaveMule, 100")
    end
  end

  describe "parse_effect" do
    test "AddItem - explicit player subject" do
      assert %{count: 200, function: :add_item, subject: :player, item_id: "gold_001"} =
               ScriptParser.parse_effect("player->additem \"gold_001\" 200")

      assert %{count: 22, function: :add_item, subject: :player, item_id: "bk_froofroo"} =
               ScriptParser.parse_effect("player->additem bk_froofroo 22")

      assert %{count: 1, function: :add_item, subject: :player, item_id: "the_thing"} =
               ScriptParser.parse_effect("player->additem \"the_thing\"")
    end

    test "AddItem - implicit self subject" do
      assert %{count: 200, function: :add_item, subject: :self, item_id: "gold_001"} =
               ScriptParser.parse_effect("additem \"gold_001\" 200")

      assert %{count: 22, function: :add_item, subject: :self, item_id: "bk_froofroo"} =
               ScriptParser.parse_effect("additem bk_froofroo 22")

      assert %{count: 1, function: :add_item, subject: :self, item_id: "the_thing"} =
               ScriptParser.parse_effect("additem \"the_thing\"")
    end

    test "AddItem - explicit NPC subject" do
      assert %{count: 200, function: :add_item, subject: "fargoth", item_id: "gold_001"} =
               ScriptParser.parse_effect("fargoth->additem \"gold_001\" 200")

      assert %{count: 22, function: :add_item, subject: "arrille", item_id: "bk_froofroo"} =
               ScriptParser.parse_effect("\"arrille\"->additem bk_froofroo 22")

      assert %{count: 1, function: :add_item, subject: "chargen class", item_id: "the_thing"} =
               ScriptParser.parse_effect("\"chargen class\"->additem \"the_thing\"")
    end

    test "RemoveItem - explicit player subject" do
      assert %{count: 200, function: :remove_item, subject: :player, item_id: "gold_001"} =
               ScriptParser.parse_effect("player->removeitem \"gold_001\" 200")

      assert %{count: 22, function: :remove_item, subject: :player, item_id: "bk_froofroo"} =
               ScriptParser.parse_effect("player->removeitem bk_froofroo 22")

      assert %{count: 1, function: :remove_item, subject: :player, item_id: "the_thing"} =
               ScriptParser.parse_effect("player->removeitem \"the_thing\"")
    end

    test "RemoveItem - implicit self subject" do
      assert %{count: 200, function: :remove_item, subject: :self, item_id: "gold_001"} =
               ScriptParser.parse_effect("removeitem \"gold_001\" 200")

      assert %{count: 22, function: :remove_item, subject: :self, item_id: "bk_froofroo"} =
               ScriptParser.parse_effect("removeitem bk_froofroo 22")

      assert %{count: 1, function: :remove_item, subject: :self, item_id: "the_thing"} =
               ScriptParser.parse_effect("removeitem \"the_thing\"")
    end

    test "RemoveItem - explicit NPC subject" do
      assert %{count: 200, function: :remove_item, subject: "fargoth", item_id: "gold_001"} =
               ScriptParser.parse_effect("\"fargoth\"->removeitem \"gold_001\" 200")

      assert %{count: 22, function: :remove_item, subject: "arrille", item_id: "bk_froofroo"} =
               ScriptParser.parse_effect("\"arrille\"->removeitem bk_froofroo 22")

      assert %{count: 1, function: :remove_item, subject: "chargen class", item_id: "the_thing"} =
               ScriptParser.parse_effect("\"chargen class\"->removeitem \"the_thing\"")
    end

    test "Drop - implicit self subject" do
      assert %{function: :drop_item, subject: :self, item_id: "slave_bracer_left", count: 1} =
               ScriptParser.parse_effect("drop slave_bracer_left 1")
    end

    test "Drop - quoted item id" do
      assert %{function: :drop_item, subject: :self, item_id: "slave_bracer_right", count: 1} =
               ScriptParser.parse_effect("drop \"slave_bracer_right\" 1")
    end

    test "ModPCFacRep - positive value" do
      assert %{value: 10, function: :mod_faction_reputation, faction_id: "imperial legion"} =
               ScriptParser.parse_effect("modpcfacrep 10 \"imperial legion\"")
    end

    test "ModPCFacRep - negative value" do
      assert %{value: -5, function: :mod_faction_reputation, faction_id: "twin lamps"} =
               ScriptParser.parse_effect("modpcfacrep -5 \"twin lamps\"")
    end

    test "ModPCFacRep - unquoted faction" do
      assert %{value: 5, function: :mod_faction_reputation, faction_id: "temple"} =
               ScriptParser.parse_effect("modpcfacrep 5 temple")
    end

    test "ModPCFacRep - comma separated" do
      assert %{value: 10, function: :mod_faction_reputation, faction_id: "imperial cult"} =
               ScriptParser.parse_effect("modpcfacrep, 10, \"imperial cult\"")
    end

    test "PCRaiseRank - quoted faction" do
      assert %{subject: :player, function: :raise_rank, value: "mages guild"} =
               ScriptParser.parse_effect("pcraiserank \"mages guild\"")
    end

    test "PCRaiseRank - unquoted faction" do
      assert %{subject: :player, function: :raise_rank, value: "temple"} =
               ScriptParser.parse_effect("pcraiserank temple")
    end

    test "PCRaiseRank - no faction specified" do
      assert %{subject: :player, function: :raise_rank, value: nil} =
               ScriptParser.parse_effect("pcraiserank")
    end

    test "PCJoinFaction - quoted faction" do
      assert %{subject: :player, function: :join_faction, value: "morag tong"} =
               ScriptParser.parse_effect("pcjoinfaction \"morag tong\"")
    end

    test "PCJoinFaction - unquoted faction" do
      assert %{subject: :player, function: :join_faction, value: "ashlanders"} =
               ScriptParser.parse_effect("pcjoinfaction ashlanders")
    end

    test "ModReputation - with player subject" do
      assert %{function: :mod_reputation, value: 3} =
               ScriptParser.parse_effect("player->modreputation 3")
    end

    test "ModDisposition - positive value" do
      assert %{subject: :self, function: :mod_disposition, value: 15} =
               ScriptParser.parse_effect("moddisposition 15")
    end

    test "ModDisposition - negative value" do
      assert %{subject: :self, function: :mod_disposition, value: -10} =
               ScriptParser.parse_effect("moddisposition -10")
    end

    # Dialogue response ID 234315643133312879 - weird!
    test "ModDisposition - negative value with space" do
      assert %{subject: :self, function: :mod_disposition, value: -30} =
               ScriptParser.parse_effect("moddisposition - 30")
    end

    test "ModDisposition - with explicit subject" do
      assert %{subject: "arrille", function: :mod_disposition, value: 40} =
               ScriptParser.parse_effect("\"arrille\"->moddisposition 40")
    end

    test "ModDisposition - with explicit unquoted subject" do
      assert %{subject: "fargoth", function: :mod_disposition, value: 40} =
               ScriptParser.parse_effect("fargoth->moddisposition 40")
    end

    test "SetDisposition - without subject" do
      assert %{subject: :self, function: :set_disposition, value: 50} =
               ScriptParser.parse_effect("setdisposition 50")
    end

    test "SetDisposition - with explicit subject" do
      assert %{subject: "bolvyn venim", function: :set_disposition, value: 10} =
               ScriptParser.parse_effect("\"bolvyn venim\"->setdisposition 10")
    end

    test "AddTopic - quoted topic" do
      assert %{function: :add_topic, topic_id: "murder of processus vitellius"} =
               ScriptParser.parse_effect("addtopic \"murder of processus vitellius\"")
    end

    test "AddTopic - with player subject" do
      assert %{function: :add_topic, topic_id: "sculptor"} =
               ScriptParser.parse_effect("player->addtopic \"sculptor\"")
    end

    test "AddTopic - extra space after command" do
      assert %{function: :add_topic, topic_id: "the star is the key"} =
               ScriptParser.parse_effect("addtopic  \"the star is the key\"")
    end

    test "AddTopic - quote inside quotes" do
      assert %{function: :add_topic, topic_id: "processus' ring"} =
               ScriptParser.parse_effect("addtopic \"processus' ring\"")
    end

    test "Enable - quoted subject" do
      assert %{function: :enable, subject: "npc name"} =
               ScriptParser.parse_effect("\"npc name\"->enable")
    end

    test "Enable - unquoted subject" do
      assert %{function: :enable, subject: "netch_bull_dead"} =
               ScriptParser.parse_effect("netch_bull_dead->enable")
    end

    test "Disable - quoted subject" do
      assert %{function: :disable, subject: "caius cosades"} =
               ScriptParser.parse_effect("\"caius cosades\"->disable")
    end

    test "Disable - unquoted subject" do
      assert %{function: :disable, subject: "ennbjof"} =
               ScriptParser.parse_effect("ennbjof->disable")
    end

    test "AddSpell - without subject" do
      assert %{function: :add_spell, subject: :self, value: "corprus"} =
               ScriptParser.parse_effect("addspell \"corprus\"")
    end

    test "AddSpell - with player subject" do
      assert %{function: :add_spell, subject: :player, value: "blight disease immunity"} =
               ScriptParser.parse_effect("player->addspell \"blight disease immunity\"")
    end

    test "RemoveSpell - without subject" do
      assert %{function: :remove_spell, subject: :self, value: "ash-chancre"} =
               ScriptParser.parse_effect("removespell \"ash-chancre\"")
    end

    test "RemoveSpell - with player subject" do
      assert %{function: :remove_spell, subject: :player, value: "werewolf blood"} =
               ScriptParser.parse_effect("player->removespell \"werewolf blood\"")
    end

    test "RemoveSpell - unquoted spell" do
      assert %{function: :remove_spell, subject: :player, value: "corprus"} =
               ScriptParser.parse_effect("player->removespell corprus")
    end

    test "ForceGreeting - without subject" do
      assert %{function: :force_greeting, subject: :self} =
               ScriptParser.parse_effect("forcegreeting")
    end

    test "ForceGreeting - with explicit subject" do
      assert %{function: :force_greeting, subject: "ahnia"} =
               ScriptParser.parse_effect("\"ahnia\"->forcegreeting")
    end

    test "Goodbye - ends dialogue" do
      assert %{function: :goodbye} = ScriptParser.parse_effect("goodbye")
    end

    test "SetFight - without subject" do
      assert %{function: :set_fight, subject: :self, value: 100} =
               ScriptParser.parse_effect("setfight 100")
    end

    test "SetFight - with explicit subject" do
      assert %{function: :set_fight, subject: "bolvyn venim", value: 100} =
               ScriptParser.parse_effect("\"bolvyn venim\"->setfight 100")
    end

    test "ModFight - without subject" do
      assert %{function: :mod_fight, subject: :self, value: 10} =
               ScriptParser.parse_effect("modfight 10")
    end

    test "ModFight - with explicit subject" do
      assert %{function: :mod_fight, subject: "fargoth", value: 30} =
               ScriptParser.parse_effect("fargoth->modfight 30")
    end

    test "ModFlee - without subject" do
      assert %{function: :mod_flee, subject: :self, value: 100} =
               ScriptParser.parse_effect("modflee 100")
    end

    test "SetFlee - without subject" do
      assert %{function: :set_flee, subject: :self, value: 20} =
               ScriptParser.parse_effect("setflee 20")
    end

    test "SetAlarm - without subject" do
      assert %{function: :set_alarm, subject: :self, value: 100} =
               ScriptParser.parse_effect("setalarm 100")
    end

    test "SetHello - without subject" do
      assert %{function: :set_hello, subject: :self, value: 0} =
               ScriptParser.parse_effect("sethello 0")
    end

    test "SetHello - with explicit subject" do
      assert %{function: :set_hello, subject: "rolf long-tooth", value: 10} =
               ScriptParser.parse_effect("\"rolf long-tooth\"->sethello 10")
    end

    test "StartScript - unquoted script id" do
      assert %{function: :start_script, script_id: "all_nerevarine"} =
               ScriptParser.parse_effect("startscript all_nerevarine")
    end

    test "StartScript - quoted script id" do
      assert %{function: :start_script, script_id: "vampire_cure_pc"} =
               ScriptParser.parse_effect("startscript \"vampire_cure_pc\"")
    end

    test "StopScript - unquoted script id" do
      assert %{function: :stop_script, script_id: "all_hortator"} =
               ScriptParser.parse_effect("stopscript all_hortator")
    end

    test "StopScript - quoted script id" do
      assert %{function: :stop_script, script_id: "vampire_cure_pc"} =
               ScriptParser.parse_effect("stopscript \"vampire_cure_pc\"")
    end

    test "StartCombat - against player without attacker" do
      assert %{function: :start_combat, subject: :self, value: "player"} =
               ScriptParser.parse_effect("startcombat player")
    end

    test "StartCombat - NPC against player" do
      assert %{function: :start_combat, subject: "bolvyn venim", value: "player"} =
               ScriptParser.parse_effect("\"bolvyn venim\"->startcombat player")
    end

    test "StartCombat - NPC against NPC" do
      assert %{function: :start_combat, subject: "afer flaccus_guard", value: "baslod"} =
               ScriptParser.parse_effect("\"afer flaccus_guard\"->startcombat \"baslod\"")
    end

    test "StopCombat - without subject" do
      assert %{function: :stop_combat, subject: :self} =
               ScriptParser.parse_effect("stopcombat")
    end

    test "StopCombat - with explicit NPC" do
      assert %{function: :stop_combat, subject: "guard"} =
               ScriptParser.parse_effect("\"guard\"->stopcombat")
    end

    test "AIFollow - follow player" do
      assert %{function: :ai_follow, subject: :self, target: :player} =
               ScriptParser.parse_effect("aifollow player 0 0 0 0")
    end

    test "AIFollow - NPC follows player" do
      assert %{function: :ai_follow, subject: "rolf long-tooth", target: :player} =
               ScriptParser.parse_effect("\"rolf long-tooth\"->aifollow player 0 0 0 0 0 0")
    end

    test "AIFollow - NPC follows another NPC" do
      assert %{function: :ai_follow, subject: "rabinna", target: "im_kilaya"} =
               ScriptParser.parse_effect("rabinna->aifollow im_kilaya 128 0 0 0 0 0 0")
    end

    test "AIFollow - quoted follow subject" do
      assert %{function: :ai_follow, subject: :self, target: "galyn arvel"} =
               ScriptParser.parse_effect("aifollow \"galyn arvel\" 0 0 0 0 0")
    end

    test "AITravel - without subject" do
      assert %{function: :ai_travel, subject: :self, target: %{x: 100, y: 200, z: 300}} =
               ScriptParser.parse_effect("aitravel 100 200 300")
    end

    test "AITravel - with explicit subject" do
      assert %{function: :ai_travel, subject: "fargoth", target: %{x: 100, y: 200, z: 300}} =
               ScriptParser.parse_effect("\"fargoth\"->aitravel 100 200 300")
    end

    test "AIWander - without subject" do
      assert %{function: :ai_wander, subject: :self, range: 256} =
               ScriptParser.parse_effect("aiwander 256 0 0 0 0 0 0 0 0 0 0 0")
    end

    test "AIWander - with explicit subject" do
      assert %{function: :ai_wander, subject: "fargoth", range: 512} =
               ScriptParser.parse_effect("\"fargoth\"->aiwander 512 0 0 0 0 0 0 0 0 0 0 0")
    end

    test "AIEscort - escort player" do
      assert %{
               function: :ai_escort,
               subject: :self,
               target: :player,
               duration: 0,
               destination: %{x: 70685, y: 126_106, z: 835}
             } =
               ScriptParser.parse_effect("aiescort player 0 70685 126106 835 0")
    end

    test "AIEscort - NPC escorts player" do
      assert %{
               function: :ai_escort,
               subject: "guard",
               target: :player,
               duration: 0,
               destination: %{x: 100, y: 200, z: 300}
             } =
               ScriptParser.parse_effect("\"guard\"->aiescort player 0 100 200 300 0")
    end

    test "Lock - without subject" do
      assert %{function: :lock, subject: :self, value: 100} =
               ScriptParser.parse_effect("lock 100")
    end

    test "Lock - with explicit subject" do
      assert %{function: :lock, subject: "in_mh_door_01_velas", value: 100} =
               ScriptParser.parse_effect("in_mh_door_01_velas->lock 100")
    end

    test "Lock - with quoted subject" do
      assert %{function: :lock, subject: "ex_mh_door_02_ignatius", value: 40} =
               ScriptParser.parse_effect("\"ex_mh_door_02_ignatius\"->lock 40")
    end

    test "Unlock - without subject" do
      assert %{function: :unlock, subject: :self} =
               ScriptParser.parse_effect("unlock")
    end

    test "Unlock - with explicit subject" do
      assert %{function: :unlock, subject: "in_mh_door_01_velas"} =
               ScriptParser.parse_effect("in_mh_door_01_velas->unlock")
    end

    test "PlaceAtPC - basic" do
      assert %{function: :place_at_pc, value: "skeleton"} =
               ScriptParser.parse_effect("placeatpc \"skeleton\" 1 50 1")
    end

    test "PlaceAtPC - unquoted object" do
      assert %{function: :place_at_pc, value: "skeleton_weak"} =
               ScriptParser.parse_effect("placeatpc skeleton_weak 1 50 1")
    end

    test "PositionCell - basic" do
      assert %{function: :position_cell, subject: :self, value: "balmora"} =
               ScriptParser.parse_effect("positioncell 100 200 300 0 \"balmora\"")
    end

    test "PositionCell - with subject" do
      assert %{function: :position_cell, subject: :player, value: "vivec"} =
               ScriptParser.parse_effect("player->positioncell 100 200 300 0 \"vivec\"")
    end

    test "Mod Stats - modstrength" do
      assert %{function: :mod_strength, subject: :self, value: 10} =
               ScriptParser.parse_effect("modstrength 10")
    end

    test "Mod Stats - modintelligence" do
      assert %{function: :mod_intelligence, subject: :self, value: 5} =
               ScriptParser.parse_effect("modintelligence 5")
    end

    test "Mod Stats - modwillpower" do
      assert %{function: :mod_willpower, subject: :self, value: 5} =
               ScriptParser.parse_effect("modwillpower 5")
    end

    test "Mod Stats - modagility" do
      assert %{function: :mod_agility, subject: :self, value: 5} =
               ScriptParser.parse_effect("modagility 5")
    end

    test "Mod Stats - modspeed" do
      assert %{function: :mod_speed, subject: "dagoth ur", value: 5} =
               ScriptParser.parse_effect("\"dagoth ur\"->modspeed 5")
    end

    test "Mod Stats - modendurance" do
      assert %{function: :mod_endurance, subject: :player, value: 5} =
               ScriptParser.parse_effect("player->modendurance 5")
    end

    test "Mod Stats - modpersonality" do
      assert %{function: :mod_personality, subject: :self, value: 5} =
               ScriptParser.parse_effect("modpersonality 5")
    end

    test "Mod Stats - modluck" do
      assert %{function: :mod_luck, subject: :self, value: 5} =
               ScriptParser.parse_effect("modluck 5")
    end

    test "Mod Stats - negative value" do
      assert %{function: :mod_strength, subject: :self, value: -5} =
               ScriptParser.parse_effect("modstrength -5")
    end

    test "ShowMap - unquoted location" do
      assert %{function: :show_map, location: "holamayan"} =
               ScriptParser.parse_effect("showmap holamayan")
    end

    test "ShowMap - quoted location" do
      assert %{function: :show_map, location: "wolverine hall"} =
               ScriptParser.parse_effect("showmap \"wolverine hall\"")
    end

    test "Set - variable assignment" do
      assert %{function: :set_variable, variable: "ownershiphhcs", value: "1"} =
               ScriptParser.parse_effect("set ownershiphhcs to 1")
    end

    test "Set - variable with expression" do
      assert %{function: :set_variable, variable: "counter", value: "counter + 1"} =
               ScriptParser.parse_effect("set counter to counter + 1")
    end

    test "Set - object property" do
      assert %{
               function: :set_variable,
               subject: "manilian scerius",
               variable: "slavestatus",
               value: "2"
             } =
               ScriptParser.parse_effect("set \"manilian scerius\".slavestatus to 2")
    end

    test "ModFactionReaction - basic" do
      assert %{
               function: :mod_faction_reaction,
               faction: "redoran",
               towards: "nerevarine",
               value: 4
             } =
               ScriptParser.parse_effect("modfactionreaction redoran nerevarine 4")
    end

    test "ModFactionReaction - quoted factions" do
      assert %{
               function: :mod_faction_reaction,
               faction: "fighters guild",
               towards: "thieves guild",
               value: -10
             } =
               ScriptParser.parse_effect(
                 "modfactionreaction \"fighters guild\" \"thieves guild\" -10"
               )
    end

    test "SetPCCrimeLevel - basic" do
      assert %{function: :set_crime_level, value: 0} =
               ScriptParser.parse_effect("setpccrimelevel 0")
    end

    test "PCClearExpelled - without faction" do
      assert %{function: :clear_expelled, faction: nil} =
               ScriptParser.parse_effect("pcclearexpelled")
    end

    test "PCClearExpelled - with faction" do
      assert %{function: :clear_expelled, faction: "mages guild"} =
               ScriptParser.parse_effect("pcclearexpelled \"mages guild\"")
    end

    test "PCExpell - with faction" do
      assert %{function: :expell, faction: "redoran"} =
               ScriptParser.parse_effect("pcexpell \"redoran\"")
    end

    test "MessageBox - basic" do
      assert %{function: :message_box, message: "your mercantile skill has increased."} =
               ScriptParser.parse_effect("messagebox \"your mercantile skill has increased.\"")
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

    test "Choice - two options" do
      assert %{
               function: :choice,
               choices: [
                 {"Yes, I found 200 septims on his body.", 1},
                 {"No, he didn't have anything on him.", 2}
               ]
             } =
               ScriptParser.parse_effect(
                 "choice \"Yes, I found 200 septims on his body.\" 1 \"No, he didn't have anything on him.\" 2"
               )
    end

    test "Choice - three options" do
      assert %{
               function: :choice,
               choices: [
                 {"Yes, I found 200 septims.", 1},
                 {"No, nothing.", 2},
                 {"I spent it.", 3}
               ]
             } =
               ScriptParser.parse_effect(
                 "choice \"Yes, I found 200 septims.\" 1 \"No, nothing.\" 2 \"I spent it.\" 3"
               )
    end

    test "Choice - with apostrophe in text" do
      assert %{
               function: :choice,
               choices: [
                 {"I don't believe you.", 5},
                 {"I understand.", 6}
               ]
             } =
               ScriptParser.parse_effect("choice \"I don't believe you.\" 5 \"I understand.\" 6")
    end

    test "Choice - with colon prefix" do
      assert %{
               function: :choice,
               choices: [
                 {"sell the item.", 1},
                 {"keep the item.", 2},
                 {"donate the item.", 3}
               ]
             } =
               ScriptParser.parse_effect(
                 "choice: \"sell the item.\" 1 \"keep the item.\" 2 \"donate the item.\" 3"
               )
    end

    test "Choice - with comma separators" do
      assert %{
               function: :choice,
               choices: [
                 {"yes", 3},
                 {"no", 4}
               ]
             } =
               ScriptParser.parse_effect("choice, \"yes\", 3, \"no\", 4")
    end

    # ─────────────────────────────────────────────────────────────────────
    # Effect commands currently parsed as %{function: :unknown, ...}.
    # Real-world reproducers:
    #
    #   activate         processusScript, treestumpScript, jeannechestScript,
    #                    jeannedoorScript, nunciusStashScript, ralenHlaaloScript, ...
    #   playsound        stal1/2/3Script (BM_Earth)
    #   cast             shrineMaarGan (TT_MaarGan)
    #   placeitem        RitualTransform (BM_WolfGiver)
    #   wakeuppc         totemScript (BM_Ceremony1)
    #   clearforcesneak  tarenScript (MS_Adulterer)
    # ─────────────────────────────────────────────────────────────────────

    test "Activate - bare command (implicit self subject)" do
      assert ScriptParser.parse_effect("activate") == %{function: :activate, subject: :self}
    end

    test "Activate - with explicit subject" do
      assert ScriptParser.parse_effect("\"jeanne_door\"->activate") ==
               %{function: :activate, subject: "jeanne_door"}
    end

    test "PlaySound - quoted sound id (global, no subject)" do
      assert ScriptParser.parse_effect("playsound \"bm pipe medium\"") ==
               %{function: :play_sound, sound_id: "bm pipe medium"}
    end

    test "PlaySound - unquoted sound id" do
      assert ScriptParser.parse_effect("playsound bm_pipe_small") ==
               %{function: :play_sound, sound_id: "bm_pipe_small"}
    end

    test "Cast - spell with target (implicit self caster)" do
      assert ScriptParser.parse_effect("cast \"shrine_maargan_sp\" player") ==
               %{
                 function: :cast,
                 subject: :self,
                 spell_id: "shrine_maargan_sp",
                 target: :player
               }
    end

    test "Cast - with explicit caster subject" do
      assert ScriptParser.parse_effect("\"caius cosades\"->cast \"fireball\" player") ==
               %{
                 function: :cast,
                 subject: "caius cosades",
                 spell_id: "fireball",
                 target: :player
               }
    end

    test "PlaceItem - literal coordinates (global, no subject)" do
      assert ScriptParser.parse_effect("placeitem \"skeleton\" 100 200 300 90") ==
               %{
                 function: :place_item,
                 item_id: "skeleton",
                 x: 100,
                 y: 200,
                 z: 300,
                 rotation: 90
               }
    end

    test "PlaceItem - local-variable coordinates (RitualTransform pattern)" do
      assert ScriptParser.parse_effect("placeitem \"ritual_ring\" xpos ypos zpos 0") ==
               %{
                 function: :place_item,
                 item_id: "ritual_ring",
                 x: "xpos",
                 y: "ypos",
                 z: "zpos",
                 rotation: 0
               }
    end

    test "WakeUpPC - bare (global)" do
      assert ScriptParser.parse_effect("wakeuppc") == %{function: :wake_up_pc}
    end

    test "ClearForceSneak - bare (implicit self subject)" do
      assert ScriptParser.parse_effect("clearforcesneak") ==
               %{function: :clear_force_sneak, subject: :self}
    end

    test "ClearForceSneak - with explicit subject" do
      assert ScriptParser.parse_effect("\"taren andoren\"->clearforcesneak") ==
               %{function: :clear_force_sneak, subject: "taren andoren"}
    end
  end

  describe "parse_condition" do
    test "GetJournalIndex - basic" do
      assert ScriptParser.parse_condition("if ( getjournalindex \"MV_SlaveMule\" <= 100 )") == %{
               left: %{function: :journal_index, arg: "MV_SlaveMule"},
               operator: :<=,
               right: %{value: 100}
             }
    end

    test "GetJournalIndex - unquoted quest id" do
      assert ScriptParser.parse_condition("if ( getjournalindex B5_RedoranHort >= 50 )") == %{
               left: %{function: :journal_index, arg: "B5_RedoranHort"},
               operator: :>=,
               right: %{value: 50}
             }
    end

    test "GetJournalIndex - equals" do
      assert ScriptParser.parse_condition("if ( getjournalindex romance_ahnassi == 33 )") == %{
               left: %{function: :journal_index, arg: "romance_ahnassi"},
               operator: :==,
               right: %{value: 33}
             }
    end

    test "GetDeadCount - basic" do
      assert ScriptParser.parse_condition("if ( getdeadcount \"Ahnia\" > 0 )") == %{
               left: %{function: :dead_count, arg: "Ahnia"},
               operator: :>,
               right: %{value: 0}
             }
    end

    test "GetItemCount - basic (implicit self subject)" do
      assert ScriptParser.parse_condition("if ( getitemcount slave_bracer_left > 0 )") == %{
               left: %{function: :item_count, subject: :self, arg: "slave_bracer_left"},
               operator: :>,
               right: %{value: 0}
             }
    end

    test "GetItemCount - with subject (canonical shape)" do
      assert ScriptParser.parse_condition(
               "if ( player->getitemcount \"katana_goldbrand_unique\" == 1 )"
             ) == %{
               left: %{subject: :player, function: :item_count, arg: "katana_goldbrand_unique"},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "GetItemCount - with nested parens" do
      assert ScriptParser.parse_condition("if ( ( player->getitemcount \"gold_001\" ) >= 1500 ") ==
               %{
                 left: %{subject: :player, function: :item_count, arg: "gold_001"},
                 operator: :>=,
                 right: %{value: 1500}
               }
    end

    test "GetPCCell - quoted cell name (parses as :current_cell, no subject)" do
      assert ScriptParser.parse_condition("if ( getpccell \"Ebonheart, Argonian Mission\" == 1 )") ==
               %{
                 left: %{function: :current_cell, arg: "Ebonheart, Argonian Mission"},
                 operator: :==,
                 right: %{value: 1}
               }
    end

    test "GetPCCell - implicit == 1" do
      assert ScriptParser.parse_condition("if ( getpccell \"vivec, arena\" )") == %{
               left: %{function: :current_cell, arg: "vivec, arena"},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "GetPCCell - not in cell" do
      assert ScriptParser.parse_condition("if ( getpccell \"abernanit\" == 0 )") == %{
               left: %{function: :current_cell, arg: "abernanit"},
               operator: :==,
               right: %{value: 0}
             }
    end

    test "OnDeath - basic" do
      assert ScriptParser.parse_condition("if ( ondeath == 1 )") == %{
               left: %{function: :on_death, subject: :self},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "OnDeath - with subject" do
      assert ScriptParser.parse_condition("if ( \"netch_giant_unique\"->ondeath == 1 )") == %{
               left: %{function: :on_death, subject: "netch_giant_unique"},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "OnActivate - basic" do
      assert ScriptParser.parse_condition("if ( onactivate == 1 )") == %{
               left: %{function: :on_activate, subject: :self},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "GetDisabled - basic" do
      assert ScriptParser.parse_condition("if ( getdisabled == 1 )") == %{
               left: %{function: :disabled, subject: :self},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "GetDisabled - with subject" do
      assert ScriptParser.parse_condition("if ( \"itermerel\"->getdisabled == 0 )") == %{
               left: %{function: :disabled, subject: "itermerel"},
               operator: :==,
               right: %{value: 0}
             }
    end

    test "GetDistance - basic" do
      assert ScriptParser.parse_condition("if ( getdistance player <= 256 )") == %{
               left: %{function: :distance, subject: :self, arg: "player"},
               operator: :<=,
               right: %{value: 256}
             }
    end

    test "GetDistance - with quoted target" do
      assert ScriptParser.parse_condition("if ( getdistance \"guar_white_unique\" <= 256 )") == %{
               left: %{function: :distance, subject: :self, arg: "guar_white_unique"},
               operator: :<=,
               right: %{value: 256}
             }
    end

    test "GetDistance - with <== (plantScript typo)" do
      assert ScriptParser.parse_condition("if ( getdistance player <== 512 )") == %{
               left: %{function: :distance, subject: :self, arg: "player"},
               operator: :<=,
               right: %{value: 512}
             }
    end

    test "GetHealth - basic" do
      assert ScriptParser.parse_condition("if ( gethealth > 0 )") == %{
               left: %{function: :health, subject: :self},
               operator: :>,
               right: %{value: 0}
             }
    end

    test "GetHealth - less than or equal" do
      assert ScriptParser.parse_condition("if ( gethealth <= 0 )") == %{
               left: %{function: :health, subject: :self},
               operator: :<=,
               right: %{value: 0}
             }
    end

    test "GetHealth - RHS is a local variable" do
      assert ScriptParser.parse_condition("if ( player->gethealth <= halfhealth )") == %{
               left: %{function: :health, subject: :player},
               operator: :<=,
               right: %{local_var: "halfhealth"}
             }
    end

    test "GetHealth - no spaces around operator" do
      assert ScriptParser.parse_condition("if ( \"Black Dart Malar\"->gethealth<1 )") == %{
               left: %{function: :health, subject: "Black Dart Malar"},
               operator: :<,
               right: %{value: 1}
             }
    end

    test "GetPCRank - parses as :rank with subject :player" do
      assert ScriptParser.parse_condition("if ( getpcrank \"redoran\" == -1 )") == %{
               left: %{function: :rank, subject: :player, arg: "redoran"},
               operator: :==,
               right: %{value: -1}
             }
    end

    test "GetSpell - basic" do
      assert ScriptParser.parse_condition("if ( player->getspell \"levitate\" == 1 )") == %{
               left: %{function: :knows_spell, subject: :player, arg: "levitate"},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "GetBlightDisease - basic" do
      assert ScriptParser.parse_condition("if ( getblightdisease == 0 )") == %{
               left: %{function: :blight_disease, subject: :self},
               operator: :==,
               right: %{value: 0}
             }
    end

    test "GetBlightDisease - with subject" do
      assert ScriptParser.parse_condition("if ( \"kwama queen_abaesen\"->getblightdisease == 1 )") ==
               %{
                 left: %{function: :blight_disease, subject: "kwama queen_abaesen"},
                 operator: :==,
                 right: %{value: 1}
               }
    end

    test "GetCommonDisease - basic" do
      assert ScriptParser.parse_condition("if ( getcommondisease == 0 )") == %{
               left: %{function: :common_disease, subject: :self},
               operator: :==,
               right: %{value: 0}
             }
    end

    test "GetCurrentAIPackage - basic" do
      assert ScriptParser.parse_condition("if ( getcurrentaipackage == 3 )") == %{
               left: %{function: :current_ai_package, subject: :self},
               operator: :==,
               right: %{value: 3}
             }
    end

    test "GetCurrentAIPackage - with subject" do
      assert ScriptParser.parse_condition(
               "if ( \"guar_llovyn_unique\"->getcurrentaipackage == 3 )"
             ) == %{
               left: %{function: :current_ai_package, subject: "guar_llovyn_unique"},
               operator: :==,
               right: %{value: 3}
             }
    end

    test "MenuMode - basic (global, no subject)" do
      assert ScriptParser.parse_condition("if ( menumode == 1 )") == %{
               left: %{function: :menu_mode},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "CellChanged - basic" do
      assert ScriptParser.parse_condition("if ( cellchanged == 0 )") == %{
               left: %{function: :cell_changed, subject: :self},
               operator: :==,
               right: %{value: 0}
             }
    end

    test "CellChanged - implicit == 1" do
      assert ScriptParser.parse_condition("if ( cellchanged )") == %{
               left: %{function: :cell_changed, subject: :self},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "IsWerewolf - basic" do
      assert ScriptParser.parse_condition("if ( iswerewolf == 1 )") == %{
               left: %{function: :is_werewolf, subject: :self},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "GetRace - basic" do
      assert ScriptParser.parse_condition("if ( player->getrace \"dark elf\" == 1 )") == %{
               left: %{function: :race, subject: :player, arg: "dark elf"},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "HasSoulGem - basic" do
      assert ScriptParser.parse_condition("if ( player->hassoulgem \"golden saint\" > 0 )") == %{
               left: %{function: :has_soul_gem, subject: :player, arg: "golden saint"},
               operator: :>,
               right: %{value: 0}
             }
    end

    test "GetLocked - basic" do
      assert ScriptParser.parse_condition("if ( getlocked == 1 )") == %{
               left: %{function: :locked, subject: :self},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "ScriptRunning - basic (global, no subject)" do
      assert ScriptParser.parse_condition("if ( scriptrunning myquest )") == %{
               left: %{function: :script_running, arg: "myquest"},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "PCExpelled - basic (global, no subject)" do
      assert ScriptParser.parse_condition("if ( pcexpelled \"mages guild\" )") == %{
               left: %{function: :expelled, arg: "mages guild"},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "GetAttacked - basic" do
      assert ScriptParser.parse_condition("if ( getattacked == 1 )") == %{
               left: %{function: :attacked, subject: :self},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "GetAttacked - with subject" do
      assert ScriptParser.parse_condition("if ( \"yagrum bagarn\"->getattacked == 1 )") == %{
               left: %{function: :attacked, subject: "yagrum bagarn"},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "DaysPassed - basic (global)" do
      assert ScriptParser.parse_condition("if ( dayspassed > 10 )") == %{
               left: %{function: :days_passed},
               operator: :>,
               right: %{value: 10}
             }
    end

    test "DaysPassed - equals" do
      assert ScriptParser.parse_condition("if ( dayspassed == 0 )") == %{
               left: %{function: :days_passed},
               operator: :==,
               right: %{value: 0}
             }
    end

    test "GameHour - greater than or equal (global)" do
      assert ScriptParser.parse_condition("if ( gamehour >= 9 )") == %{
               left: %{function: :game_hour},
               operator: :>=,
               right: %{value: 9}
             }
    end

    test "GameHour - less than" do
      assert ScriptParser.parse_condition("if ( gamehour < 22 )") == %{
               left: %{function: :game_hour},
               operator: :<,
               right: %{value: 22}
             }
    end

    test "GetAIPackageDone - basic" do
      assert ScriptParser.parse_condition("if ( getaipackagedone == 1 )") == %{
               left: %{function: :ai_package_done, subject: :self},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "GetAIPackageDone - with subject" do
      assert ScriptParser.parse_condition("if ( fargoth->getaipackagedone == 1 )") == %{
               left: %{function: :ai_package_done, subject: "fargoth"},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "GetButtonPressed - basic (global)" do
      assert ScriptParser.parse_condition("if ( getbuttonpressed != -1 )") == %{
               left: %{function: :button_pressed},
               operator: :!=,
               right: %{value: -1}
             }
    end

    test "GetCollidingPC - basic" do
      assert ScriptParser.parse_condition("if ( getcollidingpc == 1 )") == %{
               left: %{function: :colliding_pc, subject: :self},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "GetCollidingPC - implicit == 1" do
      assert ScriptParser.parse_condition("if ( getcollidingpc )") == %{
               left: %{function: :colliding_pc, subject: :self},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "GetCollidingActor - implicit == 1" do
      assert ScriptParser.parse_condition("if ( getcollidingactor )") == %{
               left: %{function: :colliding_actor, subject: :self},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "GetCurrentWeather - basic (global)" do
      assert ScriptParser.parse_condition("if ( getcurrentweather >= 5 )") == %{
               left: %{function: :current_weather},
               operator: :>=,
               right: %{value: 5}
             }
    end

    test "GetDetected - basic" do
      assert ScriptParser.parse_condition("if ( getdetected player == 1 )") == %{
               left: %{function: :detected, subject: :self, arg: "player"},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "GetDetected - with subject and quoted target" do
      assert ScriptParser.parse_condition("if ( jeanne->getdetected player == 1 )") == %{
               left: %{function: :detected, subject: "jeanne", arg: "player"},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "GetDisposition - with subject" do
      assert ScriptParser.parse_condition("if ( huleeya->getdisposition > 50 )") == %{
               left: %{function: :disposition, subject: "huleeya"},
               operator: :>,
               right: %{value: 50}
             }
    end

    test "GetEffect - basic" do
      assert ScriptParser.parse_condition("if ( geteffect seffectinvisibility == 1 )") == %{
               left: %{function: :effect, subject: :self, arg: "seffectinvisibility"},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "GetEffect - with subject" do
      assert ScriptParser.parse_condition("if ( player->geteffect seffectpoison == 1 )") == %{
               left: %{function: :effect, subject: :player, arg: "seffectpoison"},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "GetFatigue - basic" do
      assert ScriptParser.parse_condition("if ( getfatigue < 1 )") == %{
               left: %{function: :fatigue, subject: :self},
               operator: :<,
               right: %{value: 1}
             }
    end

    test "GetMagicka - basic" do
      assert ScriptParser.parse_condition("if ( getmagicka > 0 )") == %{
               left: %{function: :magicka, subject: :self},
               operator: :>,
               right: %{value: 0}
             }
    end

    test "GetLevel - basic" do
      assert ScriptParser.parse_condition("if ( player->getlevel >= 30 )") == %{
               left: %{function: :level, subject: :player},
               operator: :>=,
               right: %{value: 30}
             }
    end

    test "GetLOS - basic" do
      assert ScriptParser.parse_condition("if ( getlos player == 1 )") == %{
               left: %{function: :line_of_sight, subject: :self, arg: "player"},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "GetPos - basic" do
      assert ScriptParser.parse_condition("if ( getpos y > 1730 )") == %{
               left: %{function: :position, subject: :self, arg: "y"},
               operator: :>,
               right: %{value: 1730}
             }
    end

    test "GetPos - with subject" do
      assert ScriptParser.parse_condition("if ( \"sharn gra-muzgob\"->getpos z < -1000 )") == %{
               left: %{function: :position, subject: "sharn gra-muzgob", arg: "z"},
               operator: :<,
               right: %{value: -1000}
             }
    end

    test "GetSoundPlaying - basic (global, no subject)" do
      assert ScriptParser.parse_condition("if ( getsoundplaying \"sound_id\" == 1 )") == %{
               left: %{function: :sound_playing, arg: "sound_id"},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "GetStandingPC - basic" do
      assert ScriptParser.parse_condition("if ( getstandingpc == 1 )") == %{
               left: %{function: :standing_pc, subject: :self},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "GetStandingActor - basic" do
      assert ScriptParser.parse_condition("if ( getstandingactor == 1 )") == %{
               left: %{function: :standing_actor, subject: :self},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "GetTarget - basic" do
      assert ScriptParser.parse_condition("if ( gettarget player == 1 )") == %{
               left: %{function: :target, subject: :self, arg: "player"},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "GetTarget - with subject" do
      assert ScriptParser.parse_condition("if ( \"someone\"->gettarget player == 1 )") == %{
               left: %{function: :target, subject: "someone", arg: "player"},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "GetWaterLevel - basic (global, no subject)" do
      assert ScriptParser.parse_condition("if ( getwaterlevel != -875 )") == %{
               left: %{function: :water_level},
               operator: :!=,
               right: %{value: -875}
             }
    end

    test "GetWeaponDrawn - basic" do
      assert ScriptParser.parse_condition("if ( player->getweapondrawn == 0 )") == %{
               left: %{function: :weapon_drawn, subject: :player},
               operator: :==,
               right: %{value: 0}
             }
    end

    test "GetWerewolfKills - basic (global)" do
      assert ScriptParser.parse_condition("if ( getwerewolfkills == 0 )") == %{
               left: %{function: :werewolf_kills},
               operator: :==,
               right: %{value: 0}
             }
    end

    test "HasItemEquipped - basic" do
      assert ScriptParser.parse_condition(
               "if ( player->hasitemequipped \"steel saber_elberoth\" == 1 )"
             ) == %{
               left: %{
                 function: :has_item_equipped,
                 subject: :player,
                 arg: "steel saber_elberoth"
               },
               operator: :==,
               right: %{value: 1}
             }
    end

    test "OnKnockout - basic" do
      assert ScriptParser.parse_condition("if ( onknockout == 1 )") == %{
               left: %{function: :on_knockout, subject: :self},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "OnMurder - basic" do
      assert ScriptParser.parse_condition("if ( onmurder == 1 )") == %{
               left: %{function: :on_murder, subject: :self},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "OnPCEquip - basic" do
      assert ScriptParser.parse_condition("if ( onpcequip == 1 )") == %{
               left: %{function: :on_equip, subject: :self},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "OnPCEquip - not equal" do
      assert ScriptParser.parse_condition("if ( onpcequip != 1 )") == %{
               left: %{function: :on_equip, subject: :self},
               operator: :!=,
               right: %{value: 1}
             }
    end

    test "OnPCHitMe - basic" do
      assert ScriptParser.parse_condition("if ( onpchitme == 1 )") == %{
               left: %{function: :on_hit_me, subject: :self},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "Random - basic (global)" do
      assert ScriptParser.parse_condition("if ( random 100 > 50 )") == %{
               left: %{function: :random, arg: 100},
               operator: :>,
               right: %{value: 50}
             }
    end

    test "Random - nested parens" do
      assert ScriptParser.parse_condition("if ( ( random 100 ) < 90 )") == %{
               left: %{function: :random, arg: 100},
               operator: :<,
               right: %{value: 90}
             }
    end

    test "SayDone - basic" do
      assert ScriptParser.parse_condition("if ( saydone == 1 )") == %{
               left: %{function: :say_done, subject: :self},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "SayDone - with subject" do
      assert ScriptParser.parse_condition("if ( player->saydone == 1 )") == %{
               left: %{function: :say_done, subject: :player},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "GetInterior - implicit == 1" do
      assert ScriptParser.parse_condition("if ( getinterior )") == %{
               left: %{function: :interior, subject: :self},
               operator: :==,
               right: %{value: 1}
             }
    end

    # Format variations
    test "Subject with space before arrow" do
      assert ScriptParser.parse_condition("if ( \"duma gro-lag2\"-> getdisabled == 1 )") == %{
               left: %{function: :disabled, subject: "duma gro-lag2"},
               operator: :==,
               right: %{value: 1}
             }
    end

    test "No spaces around operator" do
      assert ScriptParser.parse_condition("if ( player->getlevel >=20 )") == %{
               left: %{function: :level, subject: :player},
               operator: :>=,
               right: %{value: 20}
             }
    end

    # Local variables — appear in either or both sides as `%{local_var: name}`.
    test "Local variable - basic" do
      assert ScriptParser.parse_condition("if ( doonce == 0 )", ["doonce"]) == %{
               left: %{local_var: "doonce"},
               operator: :==,
               right: %{value: 0}
             }
    end

    test "Local variable - greater than" do
      assert ScriptParser.parse_condition("if ( state > 1 )", ["state"]) == %{
               left: %{local_var: "state"},
               operator: :>,
               right: %{value: 1}
             }
    end

    test "Local variable - overlapping name" do
      assert ScriptParser.parse_condition("if ( randomized == 0 )", ["randomized"]) == %{
               left: %{local_var: "randomized"},
               operator: :==,
               right: %{value: 0}
             }
    end

    test "Local variable - arithmetic kept as raw string on both sides" do
      assert ScriptParser.parse_condition(
               "if ( ( moneyExpected * 2 ) < TR_m4_TT_And_GoldCounter )",
               ["moneyExpected"]
             ) == %{
               left: %{local_var: "moneyExpected * 2"},
               operator: :<,
               right: %{local_var: "TR_m4_TT_And_GoldCounter"}
             }
    end

    test "compound - getshortblade > getbluntweapon (T_ScObj_RuneHestra)" do
      assert ScriptParser.parse_condition("if ( player->getshortblade > player->getbluntweapon )") ==
               %{
                 left: %{function: :short_blade, subject: :player},
                 operator: :>,
                 right: %{function: :blunt_weapon, subject: :player}
               }
    end

    test "compound - getlongblade > getaxe (T_ScObj_RuneReman)" do
      assert ScriptParser.parse_condition("if ( player->getlongblade > player->getaxe )") == %{
               left: %{function: :long_blade, subject: :player},
               operator: :>,
               right: %{function: :axe, subject: :player}
             }
    end

    test "returns nil for non-condition" do
      assert nil == ScriptParser.parse_condition("Journal Quest 50")
      assert nil == ScriptParser.parse_condition("AddItem gold 100")
    end
  end

  describe "block boundary handling" do
    # Stray block-terminator tokens (endif, else, endwhile) and mid-body
    # local declarations currently leak through parse_single_line as
    # :unknown effects. Real-world reproducers: ColonyTimer (6 stray
    # endifs), HroldarScript, vedeleaFollow, PlagueNerile, and the
    # Example_NPC_Stuff fixture (mid-body short/long declarations).

    test "stray endif at top level produces no :unknown effect" do
      script = """
      Journal "Q" 10
      endif
      """

      ast = ScriptParser.parse(script)

      refute Enum.any?(ast.body, fn
               %ScriptParser.Effect{function: :unknown} -> true
               _ -> false
             end)
    end

    test "stray else at top level produces no :unknown effect" do
      script = """
      Journal "Q" 10
      else
      """

      ast = ScriptParser.parse(script)

      refute Enum.any?(ast.body, fn
               %ScriptParser.Effect{function: :unknown} -> true
               _ -> false
             end)
    end

    test "local declarations appearing after the header are still collected" do
      script = """
      begin TestScript
      short doOnce

      if ( doOnce == 0 )
        Journal "Q" 10
        set doOnce to 1
      endif

      short laterDecl
      """

      ast = ScriptParser.parse(script)

      assert ast.name == "testscript"
      assert "doonce" in ast.locals
      assert "laterdecl" in ast.locals

      refute Enum.any?(ast.body, fn
               %ScriptParser.Effect{function: :unknown} -> true
               _ -> false
             end)
    end
  end

  describe "while loops" do
    # Real-world reproducer: totemScript (BM_Ceremony1) summons N bears via
    # a while loop, with the place-bear command escaping to the outer scope.
    test "simple while loop produces a WhileBlock" do
      script = """
      begin TestWhile
      short temp

      while ( temp != 0 )
        set temp to temp - 1
      endwhile
      """

      expected = %ScriptParser.AST{
        name: "testwhile",
        locals: ["temp"],
        body: [
          %ScriptParser.WhileBlock{
            condition: %{
              left: %{local_var: "temp"},
              operator: :!=,
              right: %{value: 0}
            },
            body: [
              %ScriptParser.Effect{
                function: :set_variable,
                data: %{variable: "temp", value: "temp - 1"}
              }
            ]
          }
        ]
      }

      assert ScriptParser.parse(script) == expected
    end

    test "while loops can contain Journal commands" do
      # Walker contract: WhileBlock should attribute its surrounding effects
      # and conditions to nested journals the same way IfBlock does.
      script = """
      begin BearSummoner
      short count

      while ( count > 0 )
        Journal "BM_Ceremony1" 10
        set count to count - 1
      endwhile
      """

      expected = %ScriptParser.AST{
        name: "bearsummoner",
        locals: ["count"],
        body: [
          %ScriptParser.WhileBlock{
            condition: %{
              left: %{local_var: "count"},
              operator: :>,
              right: %{value: 0}
            },
            body: [
              %ScriptParser.Journal{quest_id: "bm_ceremony1", index: 10},
              %ScriptParser.Effect{
                function: :set_variable,
                data: %{variable: "count", value: "count - 1"}
              }
            ]
          }
        ]
      }

      assert ScriptParser.parse(script) == expected
    end

    test "while loops can nest inside if blocks" do
      script = """
      begin Nested
      short ready
      short count

      if ( ready == 1 )
        while ( count > 0 )
          Journal "Q" 10
        endwhile
      endif
      """

      expected = %ScriptParser.AST{
        name: "nested",
        locals: ["ready", "count"],
        body: [
          %ScriptParser.IfBlock{
            condition: %{
              left: %{local_var: "ready"},
              operator: :==,
              right: %{value: 1}
            },
            body: [
              %ScriptParser.WhileBlock{
                condition: %{
                  left: %{local_var: "count"},
                  operator: :>,
                  right: %{value: 0}
                },
                body: [
                  %ScriptParser.Journal{quest_id: "q", index: 10}
                ]
              }
            ],
            else_clause: nil
          }
        ]
      }

      assert ScriptParser.parse(script) == expected
    end
  end
end
