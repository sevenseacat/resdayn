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
        optional("FNAM", response.speaker_faction_id),
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
    {type_byte, function_code} = encode_function(condition.function, condition.value)
    operator_char = Map.fetch!(@operator_codes, condition.operator)
    name = to_string(condition.name || "")

    scvr =
      <<?0 + index::8, type_byte::binary-size(1), function_code::binary-size(2),
        operator_char::binary-size(1), name::binary>>

    [{"SCVR", scvr}, encode_value(condition.value)]
  end

  # SCVR type byte and function code encoding.
  # Type '1': standard numeric function — code is the function index ("00"-"72")
  # Types '2'/'3'/'C': variable scope — code indicates value type (fX=float, sX=int)
  # Types '4'-'B': special functions — code matches the category (JX, IX, DX, etc.)
  @variable_types %{global: "2", local: "3", not_local: "C"}

  defp encode_function(function, value) when is_map_key(@variable_types, function) do
    type_byte = Map.fetch!(@variable_types, function)
    value_code = if is_float(value), do: "fX", else: "sX"
    {type_byte, value_code}
  end

  defp encode_function(function, _value) do
    code = Map.fetch!(@function_codes, function)
    type_byte = if match?(<<_::8, "X">>, code), do: function_type_byte(code), else: "1"
    {type_byte, code}
  end

  defp function_type_byte("JX"), do: "4"
  defp function_type_byte("IX"), do: "5"
  defp function_type_byte("DX"), do: "6"
  defp function_type_byte("XX"), do: "7"
  defp function_type_byte("FX"), do: "8"
  defp function_type_byte("CX"), do: "9"
  defp function_type_byte("RX"), do: "A"
  defp function_type_byte("LX"), do: "B"

  defp encode_value(value) when is_float(value), do: {"FLTV", <<value::float32()>>}
  defp encode_value(value) when is_integer(value), do: {"INTV", <<value::int32()>>}

  defp optional(_subtype, nil), do: nil
  defp optional(subtype, value), do: {subtype, null_terminate(value)}
end
