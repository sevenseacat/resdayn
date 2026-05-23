defmodule Resdayn.Importer.Quests.ChoiceChainTest do
  use Resdayn.DataCase, async: true

  alias Resdayn.Importer.Quests.ChoiceChain

  describe "build_index/1" do
    test "indexes responses that present choices" do
      responses = [
        # Response that sets journal to 20 and presents choices 1, 2
        %{
          topic_id: Ash.CiString.new("test topic"),
          speaker_npc_id: Ash.CiString.new("test_npc"),
          conditions: [],
          script_content: %{
            "test_quest" => [
              %{
                index: 20,
                effects: [
                  %{function: :choice, choices: [{"Yes", 1}, {"No", 2}]}
                ]
              }
            ]
          }
        }
      ]

      index = ChoiceChain.build_index(responses)

      # Should have entries for both choice numbers
      assert Map.get(index, {"test topic", "test_npc", 1}) == 20
      assert Map.get(index, {"test topic", "test_npc", 2}) == 20

      # Should also have nil-speaker entries for generic lookups
      assert Map.get(index, {"test topic", nil, 1}) == 20
      assert Map.get(index, {"test topic", nil, 2}) == 20
    end

    test "ignores responses without choices" do
      responses = [
        %{
          topic_id: Ash.CiString.new("test topic"),
          speaker_npc_id: Ash.CiString.new("test_npc"),
          conditions: [],
          script_content: %{
            "test_quest" => [
              %{index: 20, effects: []}
            ]
          }
        }
      ]

      index = ChoiceChain.build_index(responses)
      assert index == %{}
    end

    test "ignores choice presentations without journal updates" do
      responses = [
        %{
          topic_id: Ash.CiString.new("test topic"),
          speaker_npc_id: nil,
          conditions: [],
          script_content: %{}
        }
      ]

      index = ChoiceChain.build_index(responses)
      assert index == %{}
    end
  end

  describe "get_from_min/3" do
    test "returns journal index for choice-conditioned response" do
      index = %{
        {"test topic", "test_npc", 1} => 20,
        {"test topic", nil, 1} => 20
      }

      response = %{
        topic_id: Ash.CiString.new("test topic"),
        speaker_npc_id: Ash.CiString.new("test_npc"),
        conditions: [
          %{function: :choice, value: %{value: 1}}
        ]
      }

      assert ChoiceChain.get_from_min(index, response, "test_quest") == 20
    end

    test "returns nil for response without choice condition" do
      index = %{{"test topic", "test_npc", 1} => 20}

      response = %{
        topic_id: Ash.CiString.new("test topic"),
        speaker_npc_id: Ash.CiString.new("test_npc"),
        conditions: []
      }

      assert ChoiceChain.get_from_min(index, response, "test_quest") == nil
    end

    test "falls back to nil-speaker lookup" do
      # Index only has nil-speaker entry
      index = %{{"test topic", nil, 1} => 20}

      response = %{
        topic_id: Ash.CiString.new("test topic"),
        speaker_npc_id: Ash.CiString.new("different_npc"),
        conditions: [
          %{function: :choice, value: %{value: 1}}
        ]
      }

      assert ChoiceChain.get_from_min(index, response, "test_quest") == 20
    end

    test "returns nil when choice not found in index" do
      index = %{{"test topic", "test_npc", 1} => 20}

      response = %{
        topic_id: Ash.CiString.new("test topic"),
        speaker_npc_id: Ash.CiString.new("test_npc"),
        conditions: [
          # Choice 99 not in index
          %{function: :choice, value: %{value: 99}}
        ]
      }

      assert ChoiceChain.get_from_min(index, response, "test_quest") == nil
    end
  end

  describe "integration with real data" do
    test "MV_DeadTaxman choice chains" do
      # Load the actual dialogue responses for MV_DeadTaxman
      responses = load_dialogue_with_scripts()

      # Filter to just the "murder of Processus Vitellius" topic
      murder_topic_responses =
        Enum.filter(responses, fn r ->
          String.downcase(to_string(r.topic_id)) == "murder of processus vitellius"
        end)

      index = ChoiceChain.build_index(murder_topic_responses)

      # The response that presents choices 1, 2 sets journal to 20
      # Check that choice 1 maps to 20
      assert Map.get(index, {"murder of processus vitellius", "chargen class", 1}) == 20

      # The response that presents choices 5, 6 sets journal to 70
      assert Map.get(index, {"murder of processus vitellius", "foryn gilnith", 5}) == 70
      assert Map.get(index, {"murder of processus vitellius", "foryn gilnith", 6}) == 70
    end
  end

  defp load_dialogue_with_scripts do
    require Ash.Query

    Resdayn.Codex.Dialogue.Response
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(not is_nil(script_content))
    |> Ash.read!()
    |> Enum.map(fn response ->
      Map.update!(
        response,
        :script_content,
        fn script_content ->
          Enum.group_by(
            Resdayn.QuestAnalyzer.ScriptParser.extract_journal_commands(script_content),
            & &1.quest_id
          )
        end
      )
    end)
  end
end
