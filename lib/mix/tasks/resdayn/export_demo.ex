defmodule Mix.Tasks.Resdayn.ExportDemo do
  @moduledoc """
  Exports a demo dialogue ESP for the Goatmire conference talk.

  Usage: mix resdayn.export_demo
  """

  use Mix.Task

  alias Resdayn.Codex.Dialogue.{Topic, Response, QuestVersion, JournalEntry}
  alias Resdayn.Codex.Dialogue.Response.Condition
  alias Resdayn.Codex.Mechanics.Script

  @output_path "../exported/goatmire_demo.esp"
  @morrowind_esm_size 79_837_557

  # Outdoors in Gnisis — the dialogue NPC who walks over and coughs
  @npc "hainab lasamsi"

  def run(_argv) do
    records = [attention_script(), greeting(), many_others(), journal()]

    {:ok, binary} = Resdayn.Exporter.build([data_file() | records])
    File.write!(@output_path, binary)

    Mix.shell().info("Wrote #{byte_size(binary)} bytes to #{@output_path}")
  end

  defp data_file do
    %Resdayn.Codex.Mechanics.DataFile{
      id: "goatmire_demo",
      filename: "goatmire_demo.esp",
      version: Decimal.new("1.0"),
      master: false,
      company: "Rebecca Le",
      description: "Goatmire conference talk demo dialogue",
      dependencies: [%{filename: "Morrowind.esm", size: @morrowind_esm_size}]
    }
  end

  # Auto-running start script: after a delay, makes the NPC walk over to the
  # player, cough, and trigger the greeting dialogue.
  defp attention_script do
    %Script{
      id: "goatmire_attention",
      start_script: true,
      local_variables: ["timer", "dist", "px", "py", "pz", "stage"],
      text: """
      Begin goatmire_attention

      float timer
      float dist
      float px
      float py
      float pz
      short stage

      ; Disable a bunch of annoying NPCs that are getting in the way
      "molvirian palenix"->Disable
      "maeonius man-llu"->Disable
      "largakh gro-bulfim"->Disable
      "abishpulu shand"->Disable
      "ughash gro-batul"->Disable

      ; stage 0: waiting for timer; 1: AITravel issued; 2: greeting fired

      if ( stage == 2 )
          return
      endif

      if ( stage == 0 )
          set timer to ( timer + GetSecondsPassed )
          if ( timer < 2 )
              return
          endif
          set px to ( Player->GetPos x ) - 30
          set py to ( Player->GetPos y ) - 30
          set pz to ( Player->GetPos z ) + 30
          ; Silence his auto-greet so it doesn't pre-empt our cough
          "#{@npc}"->SetHello 0
          "#{@npc}"->ForceRun
          "#{@npc}"->AITravel px py pz
          set stage to 1
          return
      endif

      set dist to ( "#{@npc}"->GetDistance Player )

      if ( dist < 128 )
          "#{@npc}"->Say "Vo\\d\\m\\Idl_DM001.mp3" "*cough cough*"
          MessageBox "Someone looks like they're trying to get your attention."
          set stage to 2
      endif

      End
      """
    }
  end

  defp greeting do
    %Topic{
      id: Ash.CiString.new("Greeting 0"),
      type: :greeting,
      responses: [
        %Response{
          id: "goatmire_greet_1",
          content:
            "Hello, %PCName! Though I suspect I'm not just talking to you.... " <>
              "I can sense many others listening to my words as well. " <>
              "Hello to you all!",
          speaker_npc_id: Ash.CiString.new(@npc),
          script_content: ~S(Journal "goatmire_demo" 10)
        }
      ]
    }
  end

  defp many_others do
    %Topic{
      id: Ash.CiString.new("many others"),
      type: :topic,
      responses: [
        %Response{
          id: "goatmire_choice_good",
          content: "Fantastic. Glad I could help! Enjoy the rest of the conference!",
          speaker_npc_id: Ash.CiString.new(@npc),
          conditions: [%Condition{function: :choice, operator: :=, value: 1}],
          script_content: "Goodbye
\"#{@npc}\"->ClearForceRun
\"#{@npc}\"->AIWander 50000 50000 50000 reset"
        },
        %Response{
          id: "goatmire_choice_bad",
          content: "Oh, I'm sorry to hear that. Maybe next time!",
          speaker_npc_id: Ash.CiString.new(@npc),
          conditions: [%Condition{function: :choice, operator: :=, value: 2}]
        },
        %Response{
          id: "goatmire_others_default",
          content:
            "Yes, there are lots of people reading right now! It's really quite interesting. " <>
              "Anyway, I wanted to ask you how your presentation is going - " <>
              "have you really demonstrated how interesting our world is?",
          speaker_npc_id: Ash.CiString.new(@npc),
          script_content: ~S(Choice "I think so!" 1 "Oh no it's going awfully" 2)
        }
      ]
    }
  end

  defp journal do
    %QuestVersion{
      id: Ash.CiString.new("goatmire_demo"),
      name: "Goatmire Conference Demo",
      journal_entries: [
        %JournalEntry{
          id: "goatmire_journal_1",
          index: 10,
          content:
            "I had a conversation with Hainab Lasamsi and he seemed to be aware " <>
              "that he's involved in my Goatmire talk demonstration. " <>
              "This phenomenon should be studied."
        }
      ]
    }
  end
end
