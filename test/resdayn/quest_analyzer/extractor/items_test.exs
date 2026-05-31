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
    {:ok, data: data, required_rows: Extractor.Items.required_items(data)}
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

    # In the MW/TB/BM/TR corpus, almost all "quest requires item X" gating
    # lives at the INFO-conditions layer (separate Response fields), not inside
    # the response's result-script. We only walk parsed script_content, so
    # dialogue-source `:required` rows are rare-to-nonexistent; standalone
    # scripts with `if (getitemcount ...) ... endif` are the dominant pathway.
    # Recovering INFO-level item conditions is a known gap — worth a separate
    # extractor in a later phase.
    test "rows surface from script sources", %{required_rows: rows} do
      from_scripts = Enum.filter(rows, &(not is_nil(&1.script_id)))
      refute Enum.empty?(from_scripts)
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
  end

  defp synthetic(opts) do
    commands = Keyword.fetch!(opts, :commands)
    orphan = Keyword.get(opts, :orphan, false)
    extra_ros = Keyword.get(opts, :extra_ros, %{})

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
          script_content: commands
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
