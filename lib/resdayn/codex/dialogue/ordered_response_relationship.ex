defmodule Resdayn.Codex.Dialogue.OrderedResponseRelationship do
  use Ash.Resource.ManualRelationship

  require Ash.Query

  alias Resdayn.Codex.Dialogue.Response

  @impl true
  def load(topics, _opts, _context) do
    topic_ids = Enum.map(topics, & &1.id)

    all_responses =
      Response
      |> Ash.Query.filter(topic_id in ^topic_ids)
      |> Ash.read!()

    # Group by exact topic_id
    by_topic = Enum.group_by(all_responses, fn r -> to_string(r.topic_id) end)

    # Build a secondary index by downcased topic_id (only computed once per unique key)
    by_topic_downcased =
      Map.new(by_topic, fn {k, v} -> {String.downcase(k), v} end)

    results =
      Map.new(topics, fn topic ->
        topic_id = to_string(topic.id)

        responses =
          Map.get(by_topic, topic_id) ||
            Map.get(by_topic_downcased, String.downcase(topic_id), [])

        ordered = order_by_linked_list(responses)
        {topic, ordered}
      end)

    {:ok, results}
  end

  defp order_by_linked_list(responses) do
    by_prev =
      Enum.group_by(responses, fn r ->
        r.previous_response_id && to_string(r.previous_response_id)
      end)

    heads = Map.get(by_prev, nil, [])

    Enum.flat_map(heads, &follow_chain(&1, by_prev))
  end

  defp follow_chain(response, by_prev) do
    followers = Map.get(by_prev, to_string(response.id), [])

    case followers do
      [] -> [response]
      [single] -> [response | follow_chain(single, by_prev)]
      multiple -> [response | Enum.flat_map(multiple, &follow_chain(&1, by_prev))]
    end
  end
end
