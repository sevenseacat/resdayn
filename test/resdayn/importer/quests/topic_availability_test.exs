defmodule Resdayn.Importer.Quests.TopicAvailabilityTest do
  use Resdayn.DataCase, async: true

  alias Resdayn.Importer.Quests.TopicAvailability

  describe "build/2" do
    test "tracks explicit topic additions via AddTopic in scripts" do
      responses = [
        %{
          id: "response_1",
          topic_id: "some other topic",
          content: "Hello there.",
          script_content: ~s(AddTopic "secret topic"),
          conditions: [
            %{function: :journal, name: "TestQuest", operator: :>=, value: %{value: 10}},
            %{function: :journal, name: "TestQuest", operator: :<=, value: %{value: 20}}
          ]
        }
      ]

      all_topic_ids = ["some other topic", "secret topic"]

      availability = TopicAvailability.build(responses, all_topic_ids)

      assert {10, 20} == TopicAvailability.get_bounds(availability, "secret topic", "TestQuest")
    end

    test "handles apostrophes in double-quoted topic names" do
      responses = [
        %{
          id: "response_1",
          topic_id: "some other topic",
          content: "Hello there.",
          script_content: ~s(AddTopic "Processus' Ring"),
          conditions: [
            %{function: :journal, name: "TestQuest", operator: :>=, value: %{value: 48}},
            %{function: :journal, name: "TestQuest", operator: :<=, value: %{value: 50}}
          ]
        }
      ]

      all_topic_ids = ["some other topic", "processus' ring"]

      availability = TopicAvailability.build(responses, all_topic_ids)

      assert {48, 50} == TopicAvailability.get_bounds(availability, "processus' ring", "TestQuest")
    end

    test "tracks implicit topic additions via mentions in content" do
      responses = [
        %{
          id: "response_1",
          topic_id: "main topic",
          content: "I heard about the hidden treasure in the cave.",
          script_content: nil,
          conditions: [
            %{function: :journal, name: "TreasureQuest", operator: :>=, value: %{value: 5}}
          ]
        }
      ]

      all_topic_ids = ["main topic", "hidden treasure"]

      availability = TopicAvailability.build(responses, all_topic_ids)

      assert {5, nil} ==
               TopicAvailability.get_bounds(availability, "hidden treasure", "TreasureQuest")
    end

    test "returns nil bounds for topics with no quest-specific conditions" do
      responses = [
        %{
          id: "response_1",
          topic_id: "general topic",
          content: "Let me tell you about the local rumors.",
          script_content: nil,
          conditions: []
        }
      ]

      all_topic_ids = ["general topic", "local rumors"]

      availability = TopicAvailability.build(responses, all_topic_ids)

      assert {nil, nil} == TopicAvailability.get_bounds(availability, "local rumors", "SomeQuest")
    end

    test "handles multiple sources for the same topic" do
      responses = [
        %{
          id: "response_1",
          topic_id: "topic A",
          content: "Have you heard about the mysterious stranger?",
          script_content: nil,
          conditions: [
            %{function: :journal, name: "Quest1", operator: :>=, value: %{value: 10}},
            %{function: :journal, name: "Quest1", operator: :<=, value: %{value: 15}}
          ]
        },
        %{
          id: "response_2",
          topic_id: "topic B",
          content: "The mysterious stranger was seen near the docks.",
          script_content: nil,
          conditions: [
            %{function: :journal, name: "Quest1", operator: :>=, value: %{value: 20}},
            %{function: :journal, name: "Quest1", operator: :<=, value: %{value: 30}}
          ]
        }
      ]

      all_topic_ids = ["topic A", "topic B", "mysterious stranger"]

      availability = TopicAvailability.build(responses, all_topic_ids)

      # Should return the union of both windows (earliest from_min, latest from_max)
      assert {10, 30} ==
               TopicAvailability.get_bounds(availability, "mysterious stranger", "Quest1")
    end

    test "handles strict inequality operators" do
      responses = [
        %{
          id: "response_1",
          topic_id: "topic A",
          content: "The dark secret is finally revealed.",
          script_content: nil,
          conditions: [
            %{function: :journal, name: "SecretQuest", operator: :>, value: %{value: 10}},
            %{function: :journal, name: "SecretQuest", operator: :<, value: %{value: 20}}
          ]
        }
      ]

      all_topic_ids = ["topic A", "dark secret"]

      availability = TopicAvailability.build(responses, all_topic_ids)

      # > 10 means from_min should be 11, < 20 means from_max should be 19
      assert {11, 19} == TopicAvailability.get_bounds(availability, "dark secret", "SecretQuest")
    end

    test "equality operator sets both from_min and from_max" do
      responses = [
        %{
          id: "response_1",
          topic_id: "topic A",
          content: "The ancient artifact has been found.",
          script_content: nil,
          conditions: [
            %{function: :journal, name: "ArtifactQuest", operator: :=, value: %{value: 50}}
          ]
        }
      ]

      all_topic_ids = ["topic A", "ancient artifact"]

      availability = TopicAvailability.build(responses, all_topic_ids)

      assert {50, 50} ==
               TopicAvailability.get_bounds(availability, "ancient artifact", "ArtifactQuest")
    end

    test "ignores non-journal conditions when determining bounds" do
      responses = [
        %{
          id: "response_1",
          topic_id: "topic A",
          content: "The enchanted sword awaits.",
          script_content: nil,
          conditions: [
            %{function: :item, name: "gold_001", operator: :>=, value: %{value: 100}},
            %{function: :journal, name: "SwordQuest", operator: :>=, value: %{value: 30}}
          ]
        }
      ]

      all_topic_ids = ["topic A", "enchanted sword"]

      availability = TopicAvailability.build(responses, all_topic_ids)

      # Only journal conditions affect the bounds
      assert {30, nil} ==
               TopicAvailability.get_bounds(availability, "enchanted sword", "SwordQuest")
    end

    test "case insensitive topic matching" do
      responses = [
        %{
          id: "response_1",
          topic_id: "Topic A",
          content: "The HIDDEN TEMPLE is nearby.",
          script_content: nil,
          conditions: [
            %{function: :journal, name: "TempleQuest", operator: :>=, value: %{value: 5}}
          ]
        }
      ]

      all_topic_ids = ["Topic A", "Hidden Temple"]

      availability = TopicAvailability.build(responses, all_topic_ids)

      assert {5, nil} ==
               TopicAvailability.get_bounds(availability, "hidden temple", "TempleQuest")
    end
  end
end
