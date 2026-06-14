defmodule Resdayn.QuestAnalyzer.Extractor.Transitions do
  @moduledoc """
  Discover transition rows — one per `Journal "QuestID" N` call site across
  parsed dialogue script_content and standalone scripts.

  Each row records the source (dialogue response or script) that contains
  the call, the `target_index` the call advances the quest to, and any
  precondition bounds (`from_min`/`from_max`) recovered from
  journal-comparison conditions on the source. Start/finish flagging is C6.

  ## Preconditions

  Two condition shapes contribute:

    * INFO conditions on a dialogue response (`response.conditions`) gate the
      response from being shown at all, so they apply to every journal call
      inside it. Shape: `%Condition{function: :journal, name, operator,
      value}` where `name` is the compared quest id and `value` is wrapped in
      an `%Ash.Union{}`.

    * Script conditions on a parsed command (`command.conditions`) gate a
      specific `if/then` block, so they apply only to that command's journal
      call. Shape: `%{left: %{function: :journal_index, arg}, operator,
      right: %{value}}`. We only narrow against a literal `right.value`; a
      comparison to a variable or another expression is skipped.

  Both are filtered to conditions whose subject quest matches *this* row's
  quest version; cross-quest conditions on the same source are ignored. The
  filtered conditions are reduced via operator math (`:>= N` → min=N, `:> N`
  → min=N+1, `:<= N` → max=N, `:< N` → max=N-1, `:=`/`:==` N → both N, `:!=`
  → no narrowing) and intersected: max-of-mins, min-of-maxes.

  Note the operator atoms differ by source: INFO equality is `:=` (the
  `Operator` enum), script equality is `:==` (the parser keeps the source
  text). `narrow/3` handles both.

  Within a single source, multiple `Journal X N` calls at the same index
  collapse via per-source `Enum.uniq` (defensive against parser duplicates).
  Cross-source duplicates are not possible — each row's source uniquely
  identifies it.
  """

  import Resdayn.QuestAnalyzer.Helpers
  alias Resdayn.QuestAnalyzer.LoadedData

  def discover(%LoadedData{} = data) do
    from_dialogue =
      Enum.flat_map(Map.values(data.dialogue_responses), fn response ->
        Enum.uniq(
          transition_rows(
            response.script_content,
            response.conditions || [],
            data,
            dialogue_source(response)
          )
        )
      end)

    from_scripts =
      Enum.flat_map(data.scripts, fn {script_id, parsed_commands} ->
        Enum.uniq(
          transition_rows(parsed_commands, [], data, %{
            dialogue_response_id: nil,
            dialogue_response_topic_id: nil,
            script_id: str(script_id)
          })
        )
      end)

    from_dialogue ++ from_scripts
  end

  defp transition_rows(parsed_commands, info_conditions, data, source_fields) do
    for command <- parsed_commands,
        {:ok, qv} <- [LoadedData.fetch_quest_version(data, command.quest_id)],
        not is_nil(qv.quest_id) do
      qv_key = str(qv.id)
      {from_min, from_max} = bounds(info_conditions, command.conditions, qv_key)

      %{
        quest_id: str(qv.quest_id),
        quest_version_id: qv_key,
        target_index: command.index,
        from_min: from_min,
        from_max: from_max
      }
      |> Map.merge(source_fields)
    end
  end

  # Fold both condition lists into a single {from_min, from_max} range,
  # starting unconstrained and tightening as conditions are applied.
  defp bounds(info_conditions, script_conditions, qv_key) do
    {nil, nil}
    |> reduce_conditions(info_conditions, &info_bound(&1, qv_key))
    |> reduce_conditions(script_conditions, &script_bound(&1, qv_key))
  end

  defp reduce_conditions(range, conditions, picker) do
    Enum.reduce(conditions, range, fn condition, range ->
      case picker.(condition) do
        {op, n} -> narrow(range, op, n)
        :skip -> range
      end
    end)
  end

  defp info_bound(%{function: :journal, name: name, operator: op, value: val}, qv_key) do
    if str(name) == qv_key, do: {op, unwrap_number(val)}, else: :skip
  end

  defp info_bound(_other, _qv_key), do: :skip

  defp script_bound(
         %{left: %{function: :journal_index, arg: arg}, operator: op, right: %{value: val}},
         qv_key
       ) do
    if str(arg) == qv_key, do: {op, val}, else: :skip
  end

  defp script_bound(_other, _qv_key), do: :skip

  defp narrow({lo, hi}, :>=, n), do: {tighten_min(lo, n), hi}
  defp narrow({lo, hi}, :>, n), do: {tighten_min(lo, n + 1), hi}
  defp narrow({lo, hi}, :<=, n), do: {lo, tighten_max(hi, n)}
  defp narrow({lo, hi}, :<, n), do: {lo, tighten_max(hi, n - 1)}
  defp narrow({lo, hi}, :=, n), do: {tighten_min(lo, n), tighten_max(hi, n)}
  defp narrow(range, :==, n), do: narrow(range, :=, n)
  defp narrow(range, :!=, _n), do: range

  defp tighten_min(nil, n), do: n
  defp tighten_min(existing, n), do: max(existing, n)

  defp tighten_max(nil, n), do: n
  defp tighten_max(existing, n), do: min(existing, n)

  defp unwrap_number(%Ash.Union{value: v}), do: v
  defp unwrap_number(v), do: v

  defp dialogue_source(response) do
    %{
      dialogue_response_id: str(response.id),
      dialogue_response_topic_id: str(response.topic_id),
      script_id: nil
    }
  end
end
