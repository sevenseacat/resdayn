defmodule Resdayn.Exporter.Record.Response do
  @moduledoc """
  Encodes a `Resdayn.Codex.Dialogue.Response` resource as an INFO record.

  Called by `Resdayn.Exporter.Record.Topic` for each child response —
  not dispatched to directly from `Exporter.build/1`.
  """

  import Resdayn.Parser.DataSizes
  import Resdayn.Exporter.Helpers

  alias Resdayn.Parser.Record.DialogueResponse, as: Parser

  @type_codes %{topic: 0, voice: 1, greeting: 2, persuasion: 3, journal: 4}

  @gender_codes %{male: 0, female: 1}

  # Inverted at compile time from the parser's canonical maps
  @function_codes Map.new(Parser.functions(), fn {code, atom} -> {atom, code} end)
  @operator_codes Map.new(Parser.operators(), fn {code, atom} -> {atom, code} end)

  def encode(response, type \\ :topic) do
    type_code = Map.fetch!(@type_codes, type)
    disposition = response.disposition || 0
    rank = response.speaker_faction_rank || -1
    gender = Map.get(@gender_codes, response.gender, -1)
    player_rank = response.player_faction_rank || -1

    faction =
      if(response.speaker_faction_id,
        do: null_terminate(response.speaker_faction_id),
        else: null_terminate("FFFF")
      )

    subrecords =
      [
        {"INAM", null_terminate(response.id)},
        {"PNAM", null_terminate(response.previous_response_id)},
        {"NNAM", null_terminate(response.next_response_id)},
        {"DATA",
         <<type_code::uint8(), 0::size(24), disposition::uint32(), rank::int8(), gender::int8(),
           player_rank::int8(), 0::uint8()>>},
        optional("ONAM", response.speaker_npc_id),
        optional("RNAM", response.speaker_race_id),
        optional("CNAM", response.speaker_class_id),
        {"FNAM", faction},
        optional("ANAM", response.cell_name),
        optional("DNAM", response.player_faction_id),
        optional("SNAM", response.sound_filename),
        {"NAME", null_terminate(encode_string(response.content))}
      ]
      |> Enum.reject(&is_nil/1)

    conditions = encode_conditions(response.conditions)

    script =
      if(response.script_content,
        do: [{"BNAM", null_terminate(encode_string(response.script_content))}],
        else: []
      )

    {"INFO", %{}, subrecords ++ conditions ++ script}
  end

  defp encode_conditions(nil), do: []
  defp encode_conditions([]), do: []

  defp encode_conditions(conditions) do
    # Reverse so the parser's prepend-based accumulation restores original order
    conditions
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.flat_map(fn {condition, index} -> encode_condition(condition, index) end)
  end

  defp encode_condition(condition, index) do
    {type_char, function_code} = encode_function(condition.function)
    operator_char = Map.fetch!(@operator_codes, condition.operator)
    name = to_string(condition.name || "")

    scvr =
      <<(?0 + index)::8, type_char::binary-size(1), function_code::binary-size(2),
        operator_char::binary-size(1), name::binary>>

    [{"SCVR", scvr}, encode_value(condition.value)]
  end

  # Type byte overrides for variable-scope functions
  defp encode_function(:global), do: {"2", "fX"}
  defp encode_function(:local), do: {"3", "00"}
  defp encode_function(:not_local), do: {"C", "sX"}
  defp encode_function(function), do: {"0", Map.fetch!(@function_codes, function)}

  defp encode_value(value) when is_float(value), do: {"FLTV", <<value::float32()>>}
  defp encode_value(value) when is_integer(value), do: {"INTV", <<value::int32()>>}

  defp optional(_subtype, nil), do: nil
  defp optional(subtype, value), do: {subtype, null_terminate(value)}
end
