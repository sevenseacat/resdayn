defmodule Resdayn.Codex.Dialogue.Quest.ItemsWithRoles do
  @moduledoc """
  Calculation that groups a quest's item involvements by object, pairing each
  item with the distinct roles it plays across the quest's versions.

      calculate :related_items, :term,
        {__MODULE__, involvements: :item_involvements}

  Returns a list of `%{object, object_id, roles: [reason], primary_role: reason}`,
  where `object` is the resolved typed resource (Weapon, Book, …) — or `nil`
  when the object has no concrete record — and `object_id` is the stable group
  key used for ordering. Each item's `roles` and the list itself are ordered by involvement
  importance (see `Reason.by_importance/0`), so the items that gate the most
  quest progress surface first.

  Structural twin of `ActorsWithRoles` — the difference is the subject
  relationship (`:object` → `ReferencableObject`) and the reason taxonomy
  (`ItemInvolvement.Reason` instead of `ActorInvolvement.Reason`). If a
  third involvement table appears, it's worth parameterising this pattern
  over the reason module instead of cloning a third time.
  """
  use Ash.Resource.Calculation

  alias Resdayn.Codex.QuestAnalysis.ItemInvolvement.Reason

  @impl true
  def load(_query, opts, _context) do
    # :typed_object pulls in :object (with its :type) for us, and resolves it
    # to the concrete Weapon/Book/… struct that display needs.
    [{opts[:involvements], [:reason, :typed_object]}]
  end

  @impl true
  def calculate(records, opts, _context) do
    involvements_key = opts[:involvements]

    Enum.map(records, fn record ->
      record
      |> Map.fetch!(involvements_key)
      |> Enum.group_by(& &1.object.id)
      |> Enum.map(fn {object_id, [first | _] = rows} ->
        roles =
          rows
          |> Enum.map(& &1.reason)
          |> Enum.uniq()
          |> Enum.sort_by(&Reason.importance/1)

        # Tiebreaker key is kept separate from :object because the resolved
        # typed_object can be nil (e.g. an asset-shaped object with no record).
        %{
          object: first.typed_object,
          object_id: object_id,
          roles: roles,
          primary_role: hd(roles)
        }
      end)
      |> Enum.sort_by(&{Reason.importance(&1.primary_role), to_string(&1.object_id)})
    end)
  end
end
