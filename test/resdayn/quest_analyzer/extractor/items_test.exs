defmodule Resdayn.QuestAnalyzer.Extractor.ItemsTest do
  @moduledoc """
  Tests for the item-involvement extractors. Covers both corpus-level
  smoke (real LoadedData) and focused synthetic cases for the
  condition-walking logic.
  """
  use Resdayn.IntegrationCase

  alias Resdayn.QuestAnalyzer.{Extractor, LoadedData}

  @item_object_types ~w(
    weapon armor clothing book potion ingredient
    alchemy_apparatus tool miscellaneous_item
  )a

  setup_all do
    data = LoadedData.load()

    {:ok,
     data: data,
     required_rows: Extractor.Items.required_items(data),
     effect_rows: Extractor.Items.effect_items(data)}
  end

  describe "required_items/1 — corpus" do
    test "every row has :required reason, one source, and an item-typed object",
         %{data: data, required_rows: rows} do
      refute Enum.empty?(rows)
      assert Enum.all?(rows, &(&1.reason == :required))

      assert Enum.all?(rows, fn row ->
               is_binary(row.object_id) and
                 Map.get(data.referencable_objects, row.object_id) in @item_object_types
             end)

      assert Enum.all?(rows, &exactly_one_source?/1)
    end

    test "rows surface from both source kinds (script if/then + dialogue INFO)",
         %{required_rows: rows} do
      from_dialogue = Enum.filter(rows, &(not is_nil(&1.dialogue_response_id)))
      from_scripts = Enum.filter(rows, &(not is_nil(&1.script_id)))

      refute Enum.empty?(from_dialogue)
      refute Enum.empty?(from_scripts)
    end
  end

  describe "effect_items/1 — corpus" do
    test "every row has an effect-shaped reason and an item-typed object",
         %{data: data, effect_rows: rows} do
      refute Enum.empty?(rows)
      assert Enum.all?(rows, &(&1.reason in [:received, :surrendered, :placed, :item_mention]))

      assert Enum.all?(rows, fn row ->
               is_binary(row.object_id) and
                 Map.get(data.referencable_objects, row.object_id) in @item_object_types
             end)

      assert Enum.all?(rows, &exactly_one_source?/1)
    end

    test "each effect reason actually shows up somewhere in the corpus", %{effect_rows: rows} do
      reasons = rows |> Enum.map(& &1.reason) |> MapSet.new()

      for expected <- [:received, :surrendered, :placed] do
        assert expected in reasons, "expected to see at least one #{expected} row"
      end
    end
  end

  describe "required_items/1 — synthetic" do
    test "emits a :required row when a condition reads an item's count" do
      [row] =
        synthetic(
          commands: [
            %{
              quest_id: "q1",
              conditions: [item_count_condition("test_potion", :>, 0)],
              effects: []
            }
          ]
        )
        |> Extractor.Items.required_items()

      assert row.reason == :required
      assert row.object_id == "test_potion"
      assert row.quest_id == "q1_concept"
      assert row.quest_version_id == "q1"
      assert row.dialogue_response_id == "r1"
      assert row.dialogue_response_topic_id == "t1"
      assert is_nil(row.script_id)
    end

    test "captures item references on the right side of compound conditions" do
      ids =
        synthetic(
          commands: [
            %{
              quest_id: "q1",
              conditions: [
                %{
                  left: %{function: :item_count, subject: :player, arg: "left_potion"},
                  operator: :>,
                  right: %{function: :item_count, subject: :player, arg: "right_potion"}
                }
              ],
              effects: []
            }
          ]
        )
        |> Extractor.Items.required_items()
        |> Enum.map(& &1.object_id)
        |> Enum.sort()

      assert ids == ["left_potion", "right_potion"]
    end

    test "ignores conditions whose function isn't item-referencing" do
      data =
        synthetic(
          commands: [
            %{
              quest_id: "q1",
              conditions: [
                %{
                  left: %{function: :journal_index, arg: "q1"},
                  operator: :>=,
                  right: %{value: 10}
                }
              ],
              effects: []
            }
          ]
        )

      assert Extractor.Items.required_items(data) == []
    end

    test "ignores ids that don't resolve to an item-typed ReferencableObject" do
      # `test_npc` resolves to type :npc, not an item type — should be skipped
      data =
        synthetic(
          commands: [
            %{
              quest_id: "q1",
              conditions: [item_count_condition("test_npc", :>, 0)],
              effects: []
            }
          ],
          extra_ros: %{"test_npc" => :npc}
        )

      assert Extractor.Items.required_items(data) == []
    end

    test "dedupes (quest, item, reason, source) within a single source" do
      data =
        synthetic(
          commands: [
            %{
              quest_id: "q1",
              conditions: [
                item_count_condition("test_potion", :>, 0),
                item_count_condition("test_potion", :==, 5)
              ],
              effects: []
            }
          ]
        )

      assert length(Extractor.Items.required_items(data)) == 1
    end

    test "skips orphan QuestVersions (quest_id nil)" do
      data =
        synthetic(
          commands: [
            %{
              quest_id: "q1",
              conditions: [item_count_condition("test_potion", :>, 0)],
              effects: []
            }
          ],
          orphan: true
        )

      assert Extractor.Items.required_items(data) == []
    end

    test "emits a :required row from a response's INFO-level :item condition" do
      [row] =
        synthetic(
          commands: [
            %{quest_id: "q1", conditions: [], effects: []}
          ],
          info_conditions: [
            %{function: :item, name: "test_potion", operator: :>=, value: 1}
          ]
        )
        |> Extractor.Items.required_items()

      assert row.reason == :required
      assert row.object_id == "test_potion"
      assert row.quest_id == "q1_concept"
      assert row.dialogue_response_id == "r1"
      assert is_nil(row.script_id)
    end

    test "ignores INFO conditions whose function isn't :item" do
      data =
        synthetic(
          commands: [%{quest_id: "q1", conditions: [], effects: []}],
          info_conditions: [
            %{function: :journal, name: "q1", operator: :>=, value: 10},
            %{function: :rank_low, name: nil, operator: :>=, value: 2}
          ]
        )

      assert Extractor.Items.required_items(data) == []
    end

    test "ignores INFO :item conditions whose name resolves to a non-item type" do
      data =
        synthetic(
          commands: [%{quest_id: "q1", conditions: [], effects: []}],
          info_conditions: [
            %{function: :item, name: "test_npc", operator: :>=, value: 1}
          ],
          extra_ros: %{"test_npc" => :npc}
        )

      assert Extractor.Items.required_items(data) == []
    end

    test "additem to :player → :received" do
      [row] = effect_rows_for(%{function: :add_item, subject: :player, item_id: "test_potion", count: 1})

      assert row.reason == :received
      assert row.object_id == "test_potion"
    end

    test "additem to a binary NPC subject → :placed" do
      [row] =
        effect_rows_for(
          %{function: :add_item, subject: "test_npc", item_id: "test_potion", count: 1},
          npcs: %{"test_npc" => %{id: "test_npc"}}
        )

      assert row.reason == :placed
    end

    test "additem to a container subject → :placed" do
      [row] =
        effect_rows_for(
          %{function: :add_item, subject: "test_chest", item_id: "test_potion", count: 1},
          containers: %{"test_chest" => %{id: "test_chest"}}
        )

      assert row.reason == :placed
    end

    test "additem to :self → :placed" do
      [row] = effect_rows_for(%{function: :add_item, subject: :self, item_id: "test_potion", count: 1})

      assert row.reason == :placed
    end

    test "additem to an unresolved subject → :item_mention" do
      [row] =
        effect_rows_for(%{function: :add_item, subject: "ghost", item_id: "test_potion", count: 1})

      assert row.reason == :item_mention
    end

    test "removeitem from :player → :surrendered" do
      [row] =
        effect_rows_for(%{function: :remove_item, subject: :player, item_id: "test_potion", count: 1})

      assert row.reason == :surrendered
    end

    test "removeitem from a non-player subject → :item_mention" do
      [row] =
        effect_rows_for(
          %{function: :remove_item, subject: "test_npc", item_id: "test_potion", count: 1},
          npcs: %{"test_npc" => %{id: "test_npc"}}
        )

      assert row.reason == :item_mention
    end

    test "place_at_pc and place_item → :placed" do
      assert [%{reason: :placed}] =
               effect_rows_for(%{function: :place_at_pc, item_id: "test_potion", subject: :player})

      assert [%{reason: :placed}] =
               effect_rows_for(%{function: :place_item, item_id: "test_potion"})
    end

    test "drop_item → :item_mention" do
      [row] = effect_rows_for(%{function: :drop_item, subject: :self, item_id: "test_potion"})
      assert row.reason == :item_mention
    end

    test "ignores item-mutating effects whose item_id is a non-item type" do
      data =
        synthetic(
          commands: [
            %{
              quest_id: "q1",
              conditions: [],
              effects: [%{function: :add_item, subject: :player, item_id: "test_npc", count: 1}]
            }
          ],
          extra_ros: %{"test_npc" => :npc}
        )

      assert Extractor.Items.effect_items(data) == []
    end

    test "ignores non-item-mutating effect functions" do
      data =
        synthetic(
          commands: [
            %{
              quest_id: "q1",
              conditions: [],
              effects: [%{function: :enable, subject: "test_potion"}]
            }
          ]
        )

      # `enable` isn't in the item-effect function list. (Subject-as-item is a
      # separate angle, not covered by step 3.)
      assert Extractor.Items.effect_items(data) == []
    end

    test "the same item required by INFO and script_content collapses to one row" do
      rows =
        synthetic(
          commands: [
            %{
              quest_id: "q1",
              conditions: [item_count_condition("test_potion", :>, 0)],
              effects: []
            }
          ],
          info_conditions: [
            %{function: :item, name: "test_potion", operator: :>=, value: 1}
          ]
        )
        |> Extractor.Items.required_items()

      # Same (quest, item, reason, source) tuple from two sources within one
      # response — dedupes via the per-source Enum.uniq across both walkers.
      assert length(rows) == 1
    end
  end

  defp synthetic(opts) do
    commands = Keyword.fetch!(opts, :commands)
    orphan = Keyword.get(opts, :orphan, false)
    extra_ros = Keyword.get(opts, :extra_ros, %{})
    info_conditions = Keyword.get(opts, :info_conditions, [])

    %LoadedData{
      quest_versions: %{
        "q1" => %{id: "q1", quest_id: if(orphan, do: nil, else: "q1_concept")}
      },
      scripts: %{},
      dialogue_responses: %{
        "r1" => %{
          id: "r1",
          topic_id: "t1",
          speaker_npc_id: nil,
          speaker_creature_id: nil,
          script_content: commands,
          conditions: info_conditions
        }
      },
      npcs: %{},
      creatures: %{},
      containers: %{},
      referencable_objects:
        Map.merge(
          %{
            "test_potion" => :potion,
            "left_potion" => :potion,
            "right_potion" => :potion
          },
          extra_ros
        )
    }
  end

  # Build a single-effect LoadedData and return effect_items/1's output. The
  # opts let synthetic tests inject custom npcs/creatures/containers so the
  # placement-target lookup resolves the way each scenario needs.
  defp effect_rows_for(effect, opts \\ []) do
    overrides = Keyword.take(opts, [:npcs, :creatures, :containers])

    %LoadedData{
      quest_versions: %{"q1" => %{id: "q1", quest_id: "q1_concept"}},
      scripts: %{},
      dialogue_responses: %{
        "r1" => %{
          id: "r1",
          topic_id: "t1",
          speaker_npc_id: nil,
          speaker_creature_id: nil,
          script_content: [
            %{quest_id: "q1", conditions: [], effects: [effect]}
          ],
          conditions: []
        }
      },
      npcs: Keyword.get(overrides, :npcs, %{}),
      creatures: Keyword.get(overrides, :creatures, %{}),
      containers: Keyword.get(overrides, :containers, %{}),
      referencable_objects: %{"test_potion" => :potion, "test_npc" => :npc, "test_chest" => :container}
    }
    |> Extractor.Items.effect_items()
  end

  defp item_count_condition(item_id, operator, value) do
    %{
      left: %{function: :item_count, subject: :player, arg: item_id},
      operator: operator,
      right: %{value: value}
    }
  end

  defp exactly_one_source?(row) do
    has_dialogue =
      not is_nil(row.dialogue_response_id) and not is_nil(row.dialogue_response_topic_id)

    has_script = not is_nil(row.script_id)
    has_dialogue != has_script
  end
end
