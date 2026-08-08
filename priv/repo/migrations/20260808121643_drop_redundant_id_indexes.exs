defmodule Resdayn.Repo.Migrations.DropRedundantIdIndexes do
  @moduledoc """
  Drops 17 indexes that duplicate their own tables' primary key indexes.

  When each of these tables gained an `id` foreign key to `referencable_objects`,
  the migration also created a plain btree index on `id` — but `id` is already the
  primary key, so `<table>_pkey` is a unique btree on the same single column. The
  extra index can never be preferred over it; it only costs write time, which the
  importer pays on every row.

  They came from `20250527145703` (1), `20250527152018` (13) and `20250530164249` (3).

  More importantly, this resyncs the schema with the resource snapshots. Those
  migrations wrote DDL that no snapshot ever recorded (`"index?": false` throughout),
  so AshPostgres — which diffs snapshot against snapshot, never against the database
  — has been unaware these indexes exist for 15 months. That divergence stayed
  invisible until `20260808114540` touched the same columns and generated a
  `create index` that collided with one already there.

  `containers` and `creatures` never got one, so the pattern was already inconsistent.
  """

  use Ecto.Migration

  @tables ~w(
    activators alchemy_apparatus armor books clothing creature_levelled_lists doors
    ingredients item_levelled_lists lights miscellaneous_items npcs potions sounds
    static_objects tools weapons
  )a

  def up do
    for table <- @tables, do: drop_if_exists(index(table, [:id]))
  end

  def down do
    for table <- @tables, do: create_if_not_exists(index(table, [:id]))
  end
end
