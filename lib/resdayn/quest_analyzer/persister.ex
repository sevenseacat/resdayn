defmodule Resdayn.QuestAnalyzer.Persister do
  @moduledoc """
  Bulk-persists involvement rows produced by `Resdayn.QuestAnalyzer.Extractor.*`
  modules into the `Resdayn.Codex.QuestAnalysis` tables.

  Upsert semantics make the persister idempotent: re-running the analyzer
  over the same data leaves existing rows untouched and inserts only new
  ones. Conflicts are detected by each resource's `:unique_involvement`
  identity.
  """

  alias Resdayn.Codex.QuestAnalysis.NPCInvolvement

  @doc """
  Bulk-create NPC involvement rows with on-conflict-do-nothing semantics.
  Returns the bulk-operation result from `Ash.bulk_create/4`.
  """
  def npc_involvements(rows) do
    Ash.bulk_create(
      rows,
      NPCInvolvement,
      :create,
      upsert?: true,
      upsert_identity: :unique_involvement,
      upsert_fields: [],
      return_errors?: true
    )
  end
end
