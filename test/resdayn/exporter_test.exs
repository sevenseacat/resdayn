defmodule Resdayn.ExporterTest do
  use ExUnit.Case, async: true

  alias Resdayn.Exporter

  defp data_file do
    %Resdayn.Codex.Mechanics.DataFile{
      id: "test",
      filename: "test.esp",
      version: Decimal.new("1.3"),
      master: false,
      company: "Test Author",
      description: "Test plugin",
      dependencies: [%{filename: "Morrowind.esm", size: 79_837_557}]
    }
  end

  defp build_and_parse(records) do
    {:ok, binary} = Exporter.build([data_file() | records])
    Resdayn.Parser.read_binary(binary)
  end

  describe "build/1" do
    test "builds a valid ESP from a DataFile" do
      [record] = build_and_parse([])

      assert record.type == Resdayn.Parser.Record.MainHeader
      assert record.data.header.version == 1.3
      assert record.data.header.company == "Test Author"
      assert record.data.header.description == "Test plugin"
      assert record.data.header.record_count == 0
      assert record.data.header.flags.master == false
      assert [%{filename: "Morrowind.esm", size: 79_837_557}] = record.data.dependencies
    end

    test "exports a lockpick" do
      lockpick = %Resdayn.Codex.Items.Tool{
        id: Ash.CiString.new("pick_apprentice"),
        name: "Apprentice's Lockpick",
        type: :lockpick,
        nif_model_filename: "m/Pick_Apprentice.nif",
        icon_filename: "m/Tx_lockpick_Appr.tga",
        weight: 0.25,
        value: 12,
        uses: 25,
        quality: 0.5
      }

      [_header, record] = build_and_parse([lockpick])

      assert record.type == Resdayn.Parser.Record.Lockpick
      assert record.data.id == "pick_apprentice"
      assert record.data.name == "Apprentice's Lockpick"
      assert record.data.nif_model_filename == "m/Pick_Apprentice.nif"
      assert record.data.icon_filename == "m/Tx_lockpick_Appr.tga"
      assert record.data.weight == 0.25
      assert record.data.value == 12
      assert record.data.uses == 25
      assert record.data.quality == 0.5
    end

    test "exports a book" do
      book = %Resdayn.Codex.Items.Book{
        id: Ash.CiString.new("bookskill_unarmored1"),
        name: "The Wraith's Wedding Dowry",
        value: 300,
        weight: Decimal.new("5.2"),
        nif_model_filename: "m\\Text_Quarto_01.NIF",
        icon_filename: "m\\Tx_quarto_open_01.tga",
        enchantment_points: 30,
        scroll: true,
        text:
          "this is the book content. “The poets are right.” said Kepkajna gra-Minfang. áèéïöúû",
        script_id: "my_script",
        enchantment_id: "my_enchantment",
        skill_id: 12
      }

      [_header, record] = build_and_parse([book])

      assert record.type == Resdayn.Parser.Record.Book
      assert record.data.id == "bookskill_unarmored1"
      assert record.data.name == "The Wraith's Wedding Dowry"
      assert record.data.nif_model_filename == "m\\Text_Quarto_01.NIF"
      assert record.data.icon_filename == "m\\Tx_quarto_open_01.tga"
      assert record.data.weight == 5.2
      assert record.data.value == 300
      assert record.data.skill_id == 12
      assert record.data.enchantment_points == 30
      assert record.data.flags.scroll == true

      assert record.data.text ==
               "this is the book content. “The poets are right.” said Kepkajna gra-Minfang. áèéïöúû"

      assert record.data.script_id == "my_script"
      assert record.data.enchantment_id == "my_enchantment"
    end
  end

  describe "dialogue topic" do
    test "exports a regular topic" do
      topic = %Resdayn.Codex.Dialogue.Topic{
        id: Ash.CiString.new("my topic"),
        type: :topic
      }

      [_header, record] = build_and_parse([topic])

      assert record.type == Resdayn.Parser.Record.DialogueTopic
      assert record.data.id == "my topic"
      assert record.data.type == :topic
    end

    test "exports a greeting topic" do
      topic = %Resdayn.Codex.Dialogue.Topic{
        id: Ash.CiString.new("Greeting 0"),
        type: :greeting
      }

      [_header, record] = build_and_parse([topic])

      assert record.type == Resdayn.Parser.Record.DialogueTopic
      assert record.data.id == "Greeting 0"
      assert record.data.type == :greeting
    end
  end

  describe "dialogue response" do
    test "exports a topic with a basic response" do
      topic = %Resdayn.Codex.Dialogue.Topic{
        id: Ash.CiString.new("my topic"),
        type: :topic,
        responses: [
          %Resdayn.Codex.Dialogue.Response{
            id: "response_1",
            content: "Hello there.",
            disposition: 50
          }
        ]
      }

      [_header, dial, info] = build_and_parse([topic])

      assert dial.type == Resdayn.Parser.Record.DialogueTopic
      assert dial.data.id == "my topic"

      assert info.type == Resdayn.Parser.Record.DialogueResponse
      assert info.data.id == "response_1"
      assert info.data.content == "Hello there."
      assert info.data.disposition_or_journal_index == 50
      assert info.data.type == :topic
    end

    test "exports a greeting response with the correct type" do
      topic = %Resdayn.Codex.Dialogue.Topic{
        id: Ash.CiString.new("Greeting 0"),
        type: :greeting,
        responses: [
          %Resdayn.Codex.Dialogue.Response{
            id: "greet_1",
            content: "Welcome, traveler."
          }
        ]
      }

      [_header, _dial, info] = build_and_parse([topic])

      assert info.data.type == :greeting
    end

    test "links multiple responses with PNAM/NNAM" do
      topic = %Resdayn.Codex.Dialogue.Topic{
        id: Ash.CiString.new("test topic"),
        type: :topic,
        responses: [
          %Resdayn.Codex.Dialogue.Response{id: "resp_1", content: "First"},
          %Resdayn.Codex.Dialogue.Response{id: "resp_2", content: "Second"},
          %Resdayn.Codex.Dialogue.Response{id: "resp_3", content: "Third"}
        ]
      }

      [_header, _dial, info1, info2, info3] = build_and_parse([topic])

      assert info1.data.previous_response_id == nil
      assert info1.data.next_response_id == "resp_2"

      assert info2.data.previous_response_id == "resp_1"
      assert info2.data.next_response_id == "resp_3"

      assert info3.data.previous_response_id == "resp_2"
      assert info3.data.next_response_id == nil
    end

    test "encodes gender and faction ranks" do
      topic = %Resdayn.Codex.Dialogue.Topic{
        id: Ash.CiString.new("test"),
        type: :topic,
        responses: [
          %Resdayn.Codex.Dialogue.Response{
            id: "resp_1",
            content: "Hello",
            gender: :female,
            speaker_faction_rank: 3,
            player_faction_rank: 1
          }
        ]
      }

      [_header, _dial, info] = build_and_parse([topic])

      assert info.data.gender == :female
      assert info.data.speaker_faction_rank == 3
      assert info.data.player_faction_rank == 1
    end

    test "nil gender and ranks round-trip as nil" do
      topic = %Resdayn.Codex.Dialogue.Topic{
        id: Ash.CiString.new("test"),
        type: :topic,
        responses: [
          %Resdayn.Codex.Dialogue.Response{id: "resp_1", content: "Hello"}
        ]
      }

      [_header, _dial, info] = build_and_parse([topic])

      assert info.data.gender == nil
      assert info.data.speaker_faction_rank == nil
      assert info.data.player_faction_rank == nil
    end

    test "encodes speaker NPC filter" do
      topic = %Resdayn.Codex.Dialogue.Topic{
        id: Ash.CiString.new("Greeting 0"),
        type: :greeting,
        responses: [
          %Resdayn.Codex.Dialogue.Response{
            id: "greet_1",
            content: "Hello!",
            speaker_npc_id: Ash.CiString.new("nileno dorvayn")
          }
        ]
      }

      [_header, _dial, info] = build_and_parse([topic])
      assert info.data.actor_id == "nileno dorvayn"
    end

    test "record count includes both DIAL and INFO records" do
      topic = %Resdayn.Codex.Dialogue.Topic{
        id: Ash.CiString.new("test"),
        type: :topic,
        responses: [
          %Resdayn.Codex.Dialogue.Response{id: "r1", content: "A"},
          %Resdayn.Codex.Dialogue.Response{id: "r2", content: "B"}
        ]
      }

      [header | _rest] = build_and_parse([topic])
      assert header.data.header.record_count == 3
    end
  end

  describe "dialogue conditions" do
    alias Resdayn.Codex.Dialogue.Response.Condition

    defp topic_with_conditions(conditions) do
      %Resdayn.Codex.Dialogue.Topic{
        id: Ash.CiString.new("test"),
        type: :topic,
        responses: [
          %Resdayn.Codex.Dialogue.Response{
            id: "resp_1",
            content: "Conditional response",
            conditions: conditions
          }
        ]
      }
    end

    test "encodes a choice condition" do
      topic =
        topic_with_conditions([
          %Condition{function: :choice, operator: :=, value: 1}
        ])

      [_header, _dial, info] = build_and_parse([topic])
      [condition] = info.data.conditions

      assert condition.function == :choice
      assert condition.operator == :=
      assert condition.value == 1
    end

    test "encodes a journal condition with name and integer value" do
      topic =
        topic_with_conditions([
          %Condition{function: :journal, operator: :>=, name: "my_quest", value: 10}
        ])

      [_header, _dial, info] = build_and_parse([topic])
      [condition] = info.data.conditions

      assert condition.function == :journal
      assert condition.operator == :>=
      assert condition.name == "my_quest"
      assert condition.value == 10
    end

    test "encodes a global variable condition with float value" do
      topic =
        topic_with_conditions([
          %Condition{function: :global, operator: :>, name: "my_global", value: 5.0}
        ])

      [_header, _dial, info] = build_and_parse([topic])
      [condition] = info.data.conditions

      assert condition.function == :global
      assert condition.operator == :>
      assert condition.name == "my_global"
      assert_in_delta condition.value, 5.0, 0.001
    end

    test "encodes a local variable condition" do
      topic =
        topic_with_conditions([
          %Condition{function: :local, operator: :=, name: "my_local", value: 1}
        ])

      [_header, _dial, info] = build_and_parse([topic])
      [condition] = info.data.conditions

      assert condition.function == :local
      assert condition.name == "my_local"
    end

    test "encodes a not_local condition" do
      topic =
        topic_with_conditions([
          %Condition{function: :not_local, operator: :=, name: "my_var", value: 0}
        ])

      [_header, _dial, info] = build_and_parse([topic])
      [condition] = info.data.conditions

      assert condition.function == :not_local
      assert condition.name == "my_var"
    end

    test "encodes multiple conditions in order" do
      topic =
        topic_with_conditions([
          %Condition{function: :choice, operator: :=, value: 1},
          %Condition{function: :journal, operator: :>=, name: "quest", value: 10}
        ])

      [_header, _dial, info] = build_and_parse([topic])

      assert length(info.data.conditions) == 2
      assert Enum.at(info.data.conditions, 0).function == :choice
      assert Enum.at(info.data.conditions, 1).function == :journal
    end

    test "encodes all six operators" do
      operators = [:=, :!=, :>, :>=, :<, :<=]

      for operator <- operators do
        topic =
          topic_with_conditions([
            %Condition{function: :choice, operator: operator, value: 1}
          ])

        [_header, _dial, info] = build_and_parse([topic])
        [condition] = info.data.conditions
        assert condition.operator == operator
      end
    end
  end

  describe "dialogue optional fields" do
    test "encodes result script" do
      topic = %Resdayn.Codex.Dialogue.Topic{
        id: Ash.CiString.new("test"),
        type: :greeting,
        responses: [
          %Resdayn.Codex.Dialogue.Response{
            id: "resp_1",
            content: "Welcome",
            script_content: ~S(Journal "my_quest" 10)
          }
        ]
      }

      [_header, _dial, info] = build_and_parse([topic])
      assert info.data.script_content == ~S(Journal "my_quest" 10)
    end

    test "encodes speaker faction, race, class, and cell" do
      topic = %Resdayn.Codex.Dialogue.Topic{
        id: Ash.CiString.new("test"),
        type: :topic,
        responses: [
          %Resdayn.Codex.Dialogue.Response{
            id: "resp_1",
            content: "Filtered",
            speaker_faction_id: Ash.CiString.new("Hlaalu"),
            speaker_race_id: Ash.CiString.new("Dark Elf"),
            speaker_class_id: Ash.CiString.new("Merchant"),
            cell_name: "Balmora, Hlaalu Council Manor",
            player_faction_id: Ash.CiString.new("Imperial Legion")
          }
        ]
      }

      [_header, _dial, info] = build_and_parse([topic])
      assert info.data.speaker_faction_id == "Hlaalu"
      assert info.data.speaker_race_id == "Dark Elf"
      assert info.data.speaker_class_id == "Merchant"
      assert info.data.cell_name == "Balmora, Hlaalu Council Manor"
      assert info.data.player_faction_id == "Imperial Legion"
    end

    test "nil faction omits FNAM subrecord" do
      topic = %Resdayn.Codex.Dialogue.Topic{
        id: Ash.CiString.new("test"),
        type: :topic,
        responses: [
          %Resdayn.Codex.Dialogue.Response{
            id: "resp_1",
            content: "Hello"
          }
        ]
      }

      [_header, _dial, info] = build_and_parse([topic])
      refute Map.has_key?(info.data, :speaker_faction_id)
    end

    test "encodes sound filename" do
      topic = %Resdayn.Codex.Dialogue.Topic{
        id: Ash.CiString.new("test"),
        type: :topic,
        responses: [
          %Resdayn.Codex.Dialogue.Response{
            id: "resp_1",
            content: "Hello",
            sound_filename: "vo\\n\\m\\Hlo_NM001.mp3"
          }
        ]
      }

      [_header, _dial, info] = build_and_parse([topic])
      assert info.data.sound_filename == "vo\\n\\m\\Hlo_NM001.mp3"
    end
  end

  describe "quest / journal entries" do
    test "exports a quest with a name entry and journal entries" do
      quest = %Resdayn.Codex.Dialogue.Quest{
        id: Ash.CiString.new("my_quest"),
        name: "My Quest",
        journal_entries: [
          %Resdayn.Codex.Dialogue.JournalEntry{
            id: "je_1",
            index: 10,
            content: "Started the quest."
          },
          %Resdayn.Codex.Dialogue.JournalEntry{
            id: "je_2",
            index: 100,
            content: "Finished!",
            finishes_quest: true
          }
        ]
      }

      [_header, dial, name_info, info1, info2] = build_and_parse([quest])

      assert dial.type == Resdayn.Parser.Record.DialogueTopic
      assert dial.data.id == "my_quest"
      assert dial.data.type == :journal

      # First INFO is the quest naming entry
      assert name_info.data.content == "My Quest"
      assert name_info.data.quest_name == true
      assert name_info.data.disposition_or_journal_index == 0

      # Subsequent entries are the actual journal narrative
      assert info1.data.disposition_or_journal_index == 10
      assert info1.data.content == "Started the quest."
      refute Map.get(info1.data, :quest_name)

      assert info2.data.disposition_or_journal_index == 100
      assert info2.data.content == "Finished!"
      assert info2.data.finishes_quest == true
    end

    test "journal entries are linked including name entry" do
      quest = %Resdayn.Codex.Dialogue.Quest{
        id: Ash.CiString.new("q"),
        name: "Q",
        journal_entries: [
          %Resdayn.Codex.Dialogue.JournalEntry{id: "a", index: 10, content: "A"},
          %Resdayn.Codex.Dialogue.JournalEntry{id: "b", index: 20, content: "B"}
        ]
      }

      [_header, _dial, name_info, info1, info2] = build_and_parse([quest])

      # Name entry is the head of the chain
      assert name_info.data.previous_response_id == nil
      assert name_info.data.next_response_id == "a"

      assert info1.data.previous_response_id == name_info.data.id
      assert info1.data.next_response_id == "b"

      assert info2.data.previous_response_id == "a"
      assert info2.data.next_response_id == nil
    end
  end

  describe "scripts" do
    test "exports a basic script" do
      script = %Resdayn.Codex.Mechanics.Script{
        id: "my_script",
        text: """
        Begin my_script

        short counter
        set counter to ( counter + 1 )

        End
        """,
        local_variables: ["counter"]
      }

      [_header, record] = build_and_parse([script])

      assert record.type == Resdayn.Parser.Record.Script
      assert record.data.id == "my_script"
      assert String.contains?(record.data.text, "Begin my_script")
      assert record.data.local_variables == ["counter"]
      assert record.data.num_shorts == 1
      assert record.data.num_longs == 0
      assert record.data.num_floats == 0
    end

    test "round-trips multiple local variables" do
      script = %Resdayn.Codex.Mechanics.Script{
        id: "multi_var",
        text: "Begin multi_var\nshort a\nshort b\nfloat c\nEnd",
        local_variables: ["a", "b", "c"]
      }

      [_header, record] = build_and_parse([script])

      assert record.data.local_variables == ["a", "b", "c"]
    end

    test "counts mixed local variable types" do
      script = %Resdayn.Codex.Mechanics.Script{
        id: "mixed",
        text: """
        Begin mixed

        short a
        short b
        long c
        float d
        float e

        End
        """,
        local_variables: ["a", "b", "c", "d", "e"]
      }

      [_header, record] = build_and_parse([script])

      assert record.data.num_shorts == 2
      assert record.data.num_longs == 1
      assert record.data.num_floats == 2
    end

    test "exports a start script as SCPT plus SSCR" do
      script = %Resdayn.Codex.Mechanics.Script{
        id: "auto_start",
        text: "Begin auto_start\n\nEnd",
        local_variables: [],
        start_script: true
      }

      records = build_and_parse([script])

      # Header + SCPT + SSCR
      assert length(records) == 3

      [_header, scpt, sscr] = records
      assert scpt.type == Resdayn.Parser.Record.Script
      assert sscr.type == Resdayn.Parser.Record.StartScript
      assert sscr.data.script_id == "auto_start"
    end

    test "non-start scripts do not emit SSCR" do
      script = %Resdayn.Codex.Mechanics.Script{
        id: "regular",
        text: "Begin regular\n\nEnd",
        local_variables: [],
        start_script: false
      }

      records = build_and_parse([script])
      assert length(records) == 2
    end
  end
end
