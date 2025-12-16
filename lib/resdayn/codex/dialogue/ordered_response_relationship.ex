defmodule Resdayn.Codex.Dialogue.OrderedResponseRelationship do
  use Ash.Resource.ManualRelationship

  import Ecto.Query

  alias Resdayn.Codex.Dialogue.Response

  @impl true
  def load(topics, _opts, _context) do
    Enum.reduce(topics, {:ok, %{}}, fn %{id: topic_id}, {:ok, results} ->
      head_responses =
        Response
        |> where([r], r.topic_id == ^topic_id and is_nil(r.previous_response_id))

      recursion_query =
        Response
        |> where([r], r.topic_id == ^topic_id)
        |> join(:inner, [r], ords in "ordered_responses", on: r.previous_response_id == ords.id)

      ordered_query =
        head_responses
        |> union(^recursion_query)

      ordered_list =
        {"ordered_responses", Response}
        |> recursive_ctes(true)
        |> with_cte("ordered_responses", as: ^ordered_query)
        |> Resdayn.Repo.all()

      {:ok, Map.put(results, topic_id, ordered_list)}
    end)
  end
end
