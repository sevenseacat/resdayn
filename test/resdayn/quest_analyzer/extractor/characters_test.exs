defmodule Resdayn.QuestAnalyzer.Extractor.CharactersTest do
  @moduledoc """
  Tests for the character-involvement extractors (NPCs + creatures).
  """
  use Resdayn.IntegrationCase

  alias Resdayn.QuestAnalyzer.{Extractor, LoadedData}

  setup_all do
    data = LoadedData.load()

    {:ok,
     data: data,
     speaker_rows: Extractor.Characters.dialogue_speakers(data),
     bearer_rows: Extractor.Characters.script_bearers(data),
     target_rows: Extractor.Characters.effect_targets(data)}
  end

  describe "dialogue_speakers/1" do
    test "every row has :dialogue_speaker reason and :dialogue_response source", %{speaker_rows: rows} do
      refute Enum.empty?(rows)
      assert Enum.all?(rows, &(&1.reason == :dialogue_speaker))
      assert Enum.all?(rows, &(&1.source_type == :dialogue_response))
    end

    test "emits one row per (quest, response, speaker) for A1_4_MuzgobInformant", %{speaker_rows: rows} do
      # Caius speaks 4 quest-touching responses, Sharn speaks 4 — 8 rows total.
      muzgob_rows = rows_for_quest_version(rows, "a1_4_muzgobinformant")
      assert length(muzgob_rows) == 8
    end

    test "captures all speakers across responses for A1_4_MuzgobInformant", %{speaker_rows: rows} do
      speakers =
        rows
        |> rows_for_quest_version("a1_4_muzgobinformant")
        |> Enum.map(& &1.npc_id)
        |> Enum.uniq()
        |> Enum.sort()

      assert speakers == ["caius cosades", "sharn gra-muzgob"]
    end

    test "every row's speaker is a known NPC", %{data: data, speaker_rows: rows} do
      # Rows referencing orphan speakers should be filtered out at extraction.
      row_npc_ids = rows |> Enum.map(& &1.npc_id) |> MapSet.new()
      loaded_npc_ids = data.npcs |> Map.keys() |> MapSet.new()

      assert MapSet.subset?(row_npc_ids, loaded_npc_ids)
    end

    test "honors the LoadedData quest filter" do
      data = LoadedData.load(["A1_4_MuzgobInformant"])
      rows = Extractor.Characters.dialogue_speakers(data)

      assert Enum.all?(rows, &(&1.quest_version_id == "a1_4_muzgobinformant"))
    end
  end

  describe "script_bearers/1" do
    test "every row has :script_bearer reason and :script source", %{bearer_rows: rows} do
      refute Enum.empty?(rows)
      assert Enum.all?(rows, &(&1.reason == :script_bearer))
      assert Enum.all?(rows, &(&1.source_type == :script))
    end

    test "emits a row for an NPC whose attached script touches a quest", %{bearer_rows: rows} do
      # processusScript sets journal index 10 for MV_DeadTaxman; the script is
      # attached to Processus Vitellius.
      row =
        Enum.find(rows, fn row ->
          row.npc_id == "processus vitellius" and row.quest_version_id == "mv_deadtaxman"
        end)

      refute is_nil(row)
      assert row.source_id == "processusscript"
    end
  end

  describe "effect_targets/1" do
    test "every row is either :effect_target or :effect_mention", %{target_rows: rows} do
      refute Enum.empty?(rows)
      assert Enum.all?(rows, &(&1.reason in [:effect_target, :effect_mention]))
    end

    test "emits :effect_target rows for NPCs disabled/enabled via followed scripts",
         %{target_rows: rows} do
      # TG_LootMG disables these NPCs; TG_LootMG2 re-enables them. Both scripts
      # are reached via StartScript from a quest-touching dialogue response.
      targets =
        rows
        |> Enum.filter(&(&1.quest_version_id == "tg_lootaldruhnmg" and &1.reason == :effect_target))
        |> Enum.map(& &1.npc_id)
        |> MapSet.new()

      expected = MapSet.new(["erranil", "movis darys", "edwinna elbert", "anarenen"])
      assert MapSet.subset?(expected, targets)
    end

    test "emits :effect_mention rows for soft effects somewhere in the corpus",
         %{target_rows: rows} do
      # Disposition/fight modifiers are common across quest dialogue — we just
      # verify the categorization is firing without pinning to a specific NPC.
      refute Enum.empty?(Enum.filter(rows, &(&1.reason == :effect_mention)))
    end

    test "discriminates :effect_target from :effect_mention by effect function" do
      # Synthetic data: same NPC, same source, hit by both a significant
      # (:disable) and a soft (:mod_disposition) effect. Should produce two
      # rows — one per reason.
      data = %LoadedData{
        quest_versions: %{"q1" => %{id: "q1", quest_id: "q1_concept"}},
        scripts: %{},
        dialogue_responses: %{
          "r1" => %{
            id: "r1",
            speaker_npc_id: nil,
            script_content: [
              %{
                quest_id: "q1",
                effects: [
                  %{function: :disable, subject: "test_npc"},
                  %{function: :mod_disposition, subject: "test_npc", value: 10}
                ]
              }
            ]
          }
        },
        npcs: %{"test_npc" => %{id: "test_npc"}}
      }

      reasons =
        data
        |> Extractor.Characters.effect_targets()
        |> Enum.map(& &1.reason)
        |> Enum.sort()

      assert reasons == [:effect_mention, :effect_target]
    end

    test "skips effects targeting :self or :player" do
      # Synthetic data: effects with atom subjects should produce no rows
      # (those NPCs are already captured by dialogue_speakers / script_bearers).
      data = %LoadedData{
        quest_versions: %{"q1" => %{id: "q1", quest_id: "q1_concept"}},
        scripts: %{},
        dialogue_responses: %{
          "r1" => %{
            id: "r1",
            speaker_npc_id: nil,
            script_content: [
              %{
                quest_id: "q1",
                effects: [
                  %{function: :disable, subject: :self},
                  %{function: :additem, subject: :player, item_id: "x", count: 1}
                ]
              }
            ]
          }
        },
        npcs: %{}
      }

      assert Extractor.Characters.effect_targets(data) == []
    end
  end

  defp rows_for_quest_version(rows, quest_version_id) do
    Enum.filter(rows, &(&1.quest_version_id == quest_version_id))
  end
end
