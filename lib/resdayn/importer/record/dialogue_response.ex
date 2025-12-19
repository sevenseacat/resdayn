defmodule Resdayn.Importer.Record.DialogueResponse do
  use Resdayn.Importer.Record

  def process(records, _opts) do
    npcs = Ash.read!(Resdayn.Codex.World.NPC) |> Enum.map(& &1.id) |> MapSet.new()
    creatures = Ash.read!(Resdayn.Codex.World.Creature) |> Enum.map(& &1.id) |> MapSet.new()

    processed_records =
      records
      |> chunked_dialogues()
      |> Enum.map(fn {topic, responses} ->
        responses =
          responses
          |> Enum.reverse()
          # Tamriel_Data has some "player voices" for added mods - skip
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

            fields = [
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
              :cell_name,
              :sound_filename,
              :player_faction_id,
              :deleted
            ]

            Map.from_keys(fields, nil)
            |> Map.merge(Map.take(response.data, fields))
            |> Map.put(:topic_id, topic.data.id)
            |> Map.put(:disposition, response.data[:disposition_or_journal_index])
            |> Map.put(:speaker_npc_id, speaker_npc_id)
            |> Map.put(:speaker_creature_id, speaker_creature_id)
          end)

        %{
          id: topic.data.id,
          responses: responses
        }
      end)

    %{
      type: :bulk_relationship,
      parent_resource: Resdayn.Codex.Dialogue.Topic,
      related_resource: Resdayn.Codex.Dialogue.Response,
      parent_key: :topic_id,
      id_field: :id,
      relationship_key: :responses,
      on_missing: :ignore,
      records: processed_records
    }
  end
end
