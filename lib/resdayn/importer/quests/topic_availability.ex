defmodule Resdayn.Importer.Quests.TopicAvailability do
  @moduledoc """
  Tracks when dialogue topics become available to the player.

  Topics can become available in two ways:
  1. Explicitly - via AddTopic command in a dialogue script
  2. Implicitly - when a topic name appears in dialogue response content
  """

  defstruct [:by_topic]

  @doc """
  Build a topic availability map from dialogue responses.

  ## Parameters
  - responses: List of dialogue response maps/structs with :topic_id, :content, :script_content, :conditions
  - all_topic_ids: List of all known topic IDs in the game

  ## Returns
  A %TopicAvailability{} struct that can be queried with get_bounds/3
  """
  def build(responses, all_topic_ids, opts \\ []) do
    topic_ids_set = MapSet.new(all_topic_ids, &downcase/1)
    parallel? = Keyword.get(opts, :parallel, false)

    # Only process responses with journal conditions - these are the only ones
    # that can provide quest-specific bounds. Responses without journal conditions
    # would produce records with quest_id: nil which don't match in get_bounds.
    responses =
      Enum.filter(responses, fn response ->
        conditions = get_field(response, :conditions) || []
        Enum.any?(conditions, fn c -> get_field(c, :function) == :journal end)
      end)

    process_response = fn response ->
      explicit = extract_explicit_topics(response)
      implicit = extract_implicit_topics(response, topic_ids_set)
      explicit ++ implicit
    end

    availability_list =
      if parallel? do
        # Chunk responses to reduce task overhead - each chunk processes many responses
        chunk_size = max(1, div(length(responses), System.schedulers_online() * 4))

        responses
        |> Enum.chunk_every(chunk_size)
        |> Task.async_stream(
          fn chunk ->
            Enum.flat_map(chunk, process_response)
          end,
          ordered: false,
          max_concurrency: System.schedulers_online() * 2
        )
        |> Enum.flat_map(fn {:ok, results} -> results end)
      else
        Enum.flat_map(responses, process_response)
      end

    by_topic =
      availability_list
      |> Enum.group_by(& &1.topic_id)

    %__MODULE__{by_topic: by_topic}
  end

  @doc """
  Get the journal bounds for when a topic becomes available for a specific quest.

  ## Parameters
  - availability: The %TopicAvailability{} struct from build/2
  - topic_id: The topic ID to look up
  - quest_id: The quest ID to filter by

  ## Returns
  A tuple {from_min, from_max} where either value may be nil if unbounded.
  """
  def get_bounds(%__MODULE__{by_topic: by_topic}, topic_id, quest_id) do
    availabilities = Map.get(by_topic, downcase(topic_id), [])

    # Filter to this quest
    quest_availabilities =
      availabilities
      |> Enum.filter(fn a -> a.quest_id && downcase(a.quest_id) == downcase(quest_id) end)

    if Enum.empty?(quest_availabilities) do
      {nil, nil}
    else
      # Take the union of all availability windows (earliest from_min, latest from_max)
      from_min =
        quest_availabilities
        |> Enum.map(& &1.from_min)
        |> Enum.filter(& &1)
        |> case do
          [] -> nil
          mins -> Enum.min(mins)
        end

      from_max =
        quest_availabilities
        |> Enum.map(& &1.from_max)
        |> Enum.filter(& &1)
        |> case do
          [] -> nil
          maxes -> Enum.max(maxes)
        end

      {from_min, from_max}
    end
  end

  # Extract topics explicitly added via AddTopic in script_content
  defp extract_explicit_topics(response) do
    script_content = get_field(response, :script_content) || ""

    ~r/addtopic\s+["']?([^"'\n]+)["']?/i
    |> Regex.scan(script_content)
    |> Enum.map(fn [_, topic_name] ->
      {from_min, from_max, quest_id} = extract_journal_bounds(response)

      %{
        topic_id: downcase(String.trim(topic_name)),
        quest_id: quest_id,
        from_min: from_min,
        from_max: from_max,
        source: :explicit
      }
    end)
  end

  # Extract topics implicitly added by being mentioned in response content
  defp extract_implicit_topics(response, topic_ids_set) do
    content = get_field(response, :content) || ""
    content_lower = String.downcase(content)

    topic_ids_set
    |> Enum.filter(fn topic_id ->
      # Don't match the response's own topic
      topic_id != downcase(get_field(response, :topic_id) || "") &&
        String.contains?(content_lower, topic_id)
    end)
    |> Enum.map(fn topic_id ->
      {from_min, from_max, quest_id} = extract_journal_bounds(response)

      %{
        topic_id: topic_id,
        quest_id: quest_id,
        from_min: from_min,
        from_max: from_max,
        source: :implicit
      }
    end)
  end

  # Extract journal bounds and quest_id from response conditions
  defp extract_journal_bounds(response) do
    conditions = get_field(response, :conditions) || []

    journal_conditions =
      conditions
      |> Enum.filter(fn c -> get_field(c, :function) == :journal end)

    quest_id =
      case journal_conditions do
        [first | _] -> get_field(first, :name)
        [] -> nil
      end

    from_min =
      journal_conditions
      |> Enum.filter(fn c -> get_field(c, :operator) in [:>=, :>, :=] end)
      |> Enum.map(fn c ->
        value = get_condition_value(c)
        if get_field(c, :operator) == :>, do: value + 1, else: value
      end)
      |> case do
        [] -> nil
        mins -> Enum.max(mins)
      end

    from_max =
      journal_conditions
      |> Enum.filter(fn c -> get_field(c, :operator) in [:<=, :<, :=] end)
      |> Enum.map(fn c ->
        value = get_condition_value(c)
        if get_field(c, :operator) == :<, do: value - 1, else: value
      end)
      |> case do
        [] -> nil
        maxes -> Enum.min(maxes)
      end

    {from_min, from_max, quest_id}
  end

  # Helper to get a field from either a map or struct
  defp get_field(map_or_struct, key) when is_map(map_or_struct) do
    Map.get(map_or_struct, key)
  end

  # Helper to get the integer value from a condition's value field
  defp get_condition_value(condition) do
    value = get_field(condition, :value)

    cond do
      is_integer(value) -> value
      is_map(value) && Map.has_key?(value, :value) -> value.value
      true -> 0
    end
  end

  defp downcase(nil), do: nil
  defp downcase(%Ash.CiString{} = value), do: String.downcase(to_string(value))
  defp downcase(value) when is_binary(value), do: String.downcase(value)
end
