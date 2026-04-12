defmodule Resdayn.Exporter.Record.Response do
  @moduledoc """
  Encodes a `Resdayn.Codex.Dialogue.Response` resource as an INFO record.

  Called by `Resdayn.Exporter.Record.Topic` for each child response —
  not dispatched to directly from `Exporter.build/1`.
  """

  import Resdayn.Parser.DataSizes
  import Resdayn.Exporter.Helpers

  @type_codes %{topic: 0, voice: 1, greeting: 2, persuasion: 3, journal: 4}

  @gender_codes %{male: 0, female: 1}

  def encode(response, type \\ :topic) do
    type_code = Map.fetch!(@type_codes, type)
    disposition = response.disposition || 0
    rank = response.speaker_faction_rank || -1
    gender = Map.get(@gender_codes, response.gender, -1)
    player_rank = response.player_faction_rank || -1

    subrecords =
      [
        {"INAM", null_terminate(response.id)},
        {"PNAM", null_terminate(response.previous_response_id)},
        {"NNAM", null_terminate(response.next_response_id)},
        {"DATA",
         <<type_code::uint8(), 0::size(24), disposition::uint32(), rank::int8(), gender::int8(),
           player_rank::int8(), 0::uint8()>>},
        if(response.speaker_npc_id, do: {"ONAM", null_terminate(response.speaker_npc_id)}),
        {"NAME", null_terminate(encode_string(response.content))}
      ]
      |> Enum.reject(&is_nil/1)

    {"INFO", %{}, subrecords}
  end
end
