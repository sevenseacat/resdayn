defmodule Resdayn.Importer.Quests.ChoiceChain do
  @moduledoc """
  Links choice-conditioned dialogue responses to their parent responses.

  When a dialogue response presents choices via `Choice "text" N`, follow-up
  responses handle each choice with a `choice == N` condition. This module
  builds an index to link choice handlers back to their parents, so we can
  infer the journal state (from_min) for the choice handler.

  ## Example

  Parent response (sets journal to 20, presents choices):
  ```
  Journal "MV_DeadTaxman" 20
  Choice "Yes, I found 200 septims" 1 "No, nothing" 2
  ```

  Choice handler (has choice == 1 condition, no journal condition):
  ```
  Conditions: choice == 1
  Script: Journal "MV_DeadTaxman" 30
  ```

  The choice handler's from_min should be 20 (inherited from parent).
  """

  @doc """
  Build an index mapping choice conditions to the journal index set by the parent.

  ## Parameters
  - responses: List of dialogue responses (with parsed script_content)

  ## Returns
  A map of `{topic_id, speaker_npc_id, choice_number}` -> `journal_index`
  """
  def build_index(responses) do
    responses
    |> Enum.flat_map(&extract_choice_presentations/1)
    |> Map.new()
  end

  @doc """
  Get the from_min for a choice-conditioned response by looking up its parent.

  ## Parameters
  - index: The choice presenter index from build_index/1
  - response: The dialogue response to check
  - quest_id: The quest ID we're analyzing

  ## Returns
  The journal index set by the parent, or nil if not found.
  """
  def get_from_min(index, response, _quest_id) do
    choice_condition = Enum.find(response.conditions || [], fn c -> c.function == :choice end)

    case choice_condition do
      nil ->
        nil

      %{value: %{value: choice_value}} ->
        # Look up the parent response that presented this choice
        # Try with speaker first, then without (for generic responses)
        key_with_speaker = {downcase(response.topic_id), downcase(response.speaker_npc_id), choice_value}
        key_without_speaker = {downcase(response.topic_id), nil, choice_value}

        Map.get(index, key_with_speaker) || Map.get(index, key_without_speaker)

      _ ->
        nil
    end
  end

  # Extract choice presentations from a single response.
  # Returns a list of `{{topic_id, speaker_npc_id, choice_number}, journal_index}` tuples.
  defp extract_choice_presentations(response) do
    choice_numbers = extract_choice_numbers_from_effects(response.script_content)

    case choice_numbers do
      [] ->
        []

      numbers ->
        # Get the first journal index this response sets (for any quest)
        first_index = get_first_journal_index(response.script_content)

        case first_index do
          nil ->
            []

          index ->
            # Create index entries for each choice number
            # Include both with-speaker and without-speaker keys for flexibility
            Enum.flat_map(numbers, fn choice_num ->
              topic = downcase(response.topic_id)
              speaker = downcase(response.speaker_npc_id)

              entries = [{{topic, speaker, choice_num}, index}]

              # Also add a nil-speaker entry for generic lookups
              if speaker do
                [{{topic, nil, choice_num}, index} | entries]
              else
                entries
              end
            end)
        end
    end
  end

  # Extract choice numbers from parsed script_content.
  # script_content is a map of quest_id -> [commands], where each command has effects.
  defp extract_choice_numbers_from_effects(script_content) when is_map(script_content) do
    script_content
    |> Map.values()
    |> List.flatten()
    |> Enum.flat_map(fn cmd ->
      cmd.effects
      |> Enum.filter(fn e -> e[:function] == :choice end)
      |> Enum.flat_map(fn e -> e[:choices] || [] end)
      |> Enum.map(fn {_text, num} -> num end)
    end)
    |> Enum.uniq()
  end

  defp extract_choice_numbers_from_effects(_), do: []

  # Get the first journal index set by this response (across all quests).
  defp get_first_journal_index(script_content) when is_map(script_content) do
    script_content
    |> Map.values()
    |> List.flatten()
    |> Enum.map(& &1.index)
    |> List.first()
  end

  defp get_first_journal_index(_), do: nil

  defp downcase(nil), do: nil
  defp downcase(%Ash.CiString{} = value), do: String.downcase(to_string(value))
  defp downcase(value) when is_binary(value), do: String.downcase(value)
end
