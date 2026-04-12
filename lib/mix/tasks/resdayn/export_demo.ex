defmodule Mix.Tasks.Resdayn.ExportDemo do
  @moduledoc """
  Exports a demo dialogue ESP for the Goatmire conference talk.

  Usage: mix resdayn.export_demo
  """

  use Mix.Task

  alias Resdayn.Codex.Dialogue.{Topic, Response}
  alias Resdayn.Codex.Dialogue.Response.Condition

  @output_path "priv/goatmire_demo.esp"
  @morrowind_esm_size 79_837_557
  @npc "nileno dorvayn"

  def run(_argv) do
    records = [greeting(), many_others()]

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

  # Nileno greets the player and sets a journal entry
  # TODO: add journal script_content once Quest encoder is ready
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
          speaker_npc_id: Ash.CiString.new(@npc)
        }
      ]
    }
  end

  # "many others" topic with Choice-based branching
  defp many_others do
    %Topic{
      id: Ash.CiString.new("many others"),
      type: :topic,
      responses: [
        # Choice responses first — Morrowind evaluates first match
        %Response{
          id: "goatmire_choice_good",
          content: "Fantastic. Glad I could help! Enjoy the rest of the conference!",
          speaker_npc_id: Ash.CiString.new(@npc),
          conditions: [%Condition{function: :choice, operator: :=, value: 1}]
        },
        %Response{
          id: "goatmire_choice_bad",
          content: "Oh, I'm sorry to hear that. Maybe next time!",
          speaker_npc_id: Ash.CiString.new(@npc),
          conditions: [%Condition{function: :choice, operator: :=, value: 2}]
        },
        # Default response — shown when no choice has been made yet
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
end
