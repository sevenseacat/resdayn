defmodule Resdayn.QuestAnalyzer.Persister do
  @moduledoc """
  Bulk-persists rows produced by `Resdayn.QuestAnalyzer.Extractor.*` modules
  into the `Resdayn.Codex.QuestAnalysis` tables.

  Involvement tables upsert against a composite uniqueness identity, so
  re-running the analyzer over the same data leaves existing rows untouched
  and inserts only new ones. Transitions have no honest key (see `transitions/1`)
  and are rebuilt per run instead.
  """

  require Ash.Query

  alias Resdayn.Codex.QuestAnalysis.{ActorInvolvement, ItemInvolvement, Transition}

  @doc """
  Bulk-create actor involvement rows with on-conflict-do-nothing semantics.
  Returns the bulk-operation result from `Ash.bulk_create/4`.
  """
  def actor_involvements(rows), do: bulk_upsert(rows, ActorInvolvement, :unique_involvement)

  @doc """
  Bulk-create item involvement rows with on-conflict-do-nothing semantics.
  """
  def item_involvements(rows), do: bulk_upsert(rows, ItemInvolvement, :unique_involvement)

  @doc """
  Rebuild transition rows for the quests these rows touch.

  Transitions have no honest uniqueness key (see `Transition`), so we can't
  upsert. Instead we clear the existing rows for the affected quest versions
  and insert the freshly-extracted set. Scoping the delete to the incoming
  rows' quest versions keeps a quest-scoped analyzer run from wiping other
  quests' transitions.
  """
  def transitions(rows) do
    rows
    |> Enum.map(& &1.quest_version_id)
    |> Enum.uniq()
    |> clear_transitions()

    Ash.bulk_create!(rows, Transition, :create, return_errors?: true)
  end

  defp clear_transitions([]), do: :ok

  defp clear_transitions(quest_version_ids) do
    Transition
    |> Ash.Query.filter(quest_version_id in ^quest_version_ids)
    |> Ash.bulk_destroy!(:destroy, %{}, return_errors?: true)
  end

  defp bulk_upsert(rows, resource, identity) do
    Ash.bulk_create!(rows, resource, :create,
      upsert?: true,
      upsert_identity: identity,
      upsert_fields: [],
      return_errors?: true
    )
  end
end
