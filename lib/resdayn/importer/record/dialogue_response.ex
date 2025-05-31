defmodule Resdayn.Importer.Record.DialogueResponse do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    npcs = Ash.read!(Resdayn.Codex.World.NPC) |> Enum.map(& &1.id)
    creatures = Ash.read!(Resdayn.Codex.World.Creature) |> Enum.map(& &1.id)

    records
    |> chunked_dialogues()
    |> Enum.map(fn {topic, responses} ->
      responses =
        responses
        |> Enum.reverse()
        # Tamriel_Data has some "player voices" for added mods - skipppp
        |> Enum.reject(&(&1.data[:actor_id] == "player"))
        |> Enum.map(fn response ->
          actor_id = response.data[:actor_id]

          {speaker_npc_id, speaker_creature_id} =
            cond do
              actor_id == nil ->
                {nil, nil}

              actor_id in npcs ->
                {actor_id, nil}

              actor_id in creatures ->
                {nil, actor_id}

              true ->
                raise RuntimeError, "Invalid dialogue condition actor id received: #{actor_id}"
            end

          response.data
          |> Map.take([
            :id,
            :content,
            :script_content,
            :speaker_faction_rank,
            :player_faction_rank,
            :gender,
            :conditions,
            :previous_response_id,
            :next_response_id,
            :speaker_class_id,
            :speaker_faction_id,
            :cell_id,
            :sound_filename,
            :player_faction_id
          ])
          |> Map.put(:topic_id, topic.data.id)
          |> Map.put(:disposition, response.data.disposition_or_journal_index)
          |> Map.put(:speaker_npc_id, speaker_npc_id)
          |> Map.put(:speaker_creature_id, speaker_creature_id)
        end)

      topic.data
      |> Map.take([:id])
      |> Map.put(:responses, responses)
    end)
    |> separate_for_import(Resdayn.Codex.Dialogue.Topic, action: :import_relationships)
  end
end
