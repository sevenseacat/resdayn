defmodule Resdayn.QuestAnalyzer.Persister do
  @moduledoc """
  Bulk-persists rows produced by `Resdayn.QuestAnalyzer.Extractor.*` modules
  into the `Resdayn.Codex.QuestAnalysis` tables.

  Upsert semantics make the persister idempotent: re-running the analyzer
  over the same data leaves existing rows untouched and inserts only new
  ones. Conflicts are detected by each resource's composite uniqueness
  identity.
  """

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
  Bulk-create transition rows with on-conflict-do-nothing semantics.
  """
  def transitions(rows), do: bulk_upsert(rows, Transition, :unique_transition)

  defp bulk_upsert(rows, resource, identity) do
    Ash.bulk_create(rows, resource, :create,
      upsert?: true,
      upsert_identity: identity,
      upsert_fields: [],
      return_errors?: true
    )
  end
end
