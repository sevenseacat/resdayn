defmodule Resdayn.Importer.ChildrenUpserter do
  @moduledoc """
  Bulk upsert child/relationship records (CellReferences, InventoryItems, etc.).

  Each child belongs to a parent and has a composite key (e.g. `{id, cell_id}`).
  Input is a list of parent maps, each containing a nested list of children.

  Handles:
  - Flattening parent→children with proper foreign keys
  - `on_missing: :destroy` — deleting children that no longer appear
  - Explicit deletes (e.g. DELE records in cell references)

  Delegates record preparation and SQL execution to `Resdayn.Importer.Upsert`.

  ## Options

  * `:parent_resource` - The parent resource module (e.g., Cell)
  * `:related_resource` - The child resource module (e.g., CellReference)
  * `:parent_key` - Foreign key field linking to parent (e.g., :cell_id)
  * `:id_field` - Unique identifier field within parent scope (default: :id)
  * `:relationship_key` - Key in records containing new children (default: :relationships)
  * `:deleted_key` - Key in records containing deleted child IDs (optional)
  * `:on_missing` - `:ignore` (keep existing) or `:destroy` (delete missing)
  * `:source_file_id` - The source file being imported (for tracking)
  """

  require Logger

  alias Resdayn.Repo
  alias Resdayn.Importer.Upsert

  import Ecto.Query

  def import(records, opts) do
    related_resource = Keyword.fetch!(opts, :related_resource)
    parent_key = Keyword.fetch!(opts, :parent_key)
    id_field = Keyword.get(opts, :id_field, :id)
    relationship_key = Keyword.get(opts, :relationship_key, :relationships)
    deleted_key = Keyword.get(opts, :deleted_key)
    on_missing = Keyword.get(opts, :on_missing, :ignore)
    source_file_id = Keyword.get(opts, :source_file_id)

    table = AshPostgres.DataLayer.Info.table(related_resource)
    attributes = Ash.Resource.Info.attributes(related_resource)
    has_source_file_ids = Enum.any?(attributes, &(&1.name == :source_file_ids))

    # Flatten parent→children, preparing each child for insertion
    {flatten_time, {all_upserts, all_deletes}} =
      :timer.tc(
        fn ->
          flatten_children(records, attributes,
            parent_key: parent_key,
            id_field: id_field,
            relationship_key: relationship_key,
            deleted_key: deleted_key,
            source_file_id: source_file_id,
            has_source_file_ids: has_source_file_ids
          )
        end,
        :millisecond
      )

    Logger.info(
      "ChildrenUpserter: Flattened #{length(all_upserts)} upserts, #{length(all_deletes)} deletes in #{flatten_time}ms"
    )

    # Handle on_missing: :destroy
    {destroy_time, missing_deletes} =
      if on_missing == :destroy do
        :timer.tc(
          fn -> find_missing_keys(records, all_upserts, table, id_field, parent_key) end,
          :millisecond
        )
      else
        {0, []}
      end

    if on_missing == :destroy do
      Logger.info(
        "ChildrenUpserter: Found #{length(missing_deletes)} missing records to delete in #{destroy_time}ms"
      )
    end

    total_deletes = all_deletes ++ missing_deletes

    # Execute upserts
    {upsert_time, upsert_count} =
      :timer.tc(
        fn ->
          Upsert.execute(all_upserts,
            table: table,
            conflict_keys: [id_field, parent_key],
            source_file_id: source_file_id,
            has_source_file_ids: has_source_file_ids
          )
        end,
        :millisecond
      )

    Logger.info("ChildrenUpserter: Upserted #{upsert_count} records in #{upsert_time}ms")

    # Execute deletes
    {delete_time, delete_count} =
      :timer.tc(
        fn -> execute_deletes(total_deletes, table, id_field, parent_key) end,
        :millisecond
      )

    Logger.info("ChildrenUpserter: Deleted #{delete_count} records in #{delete_time}ms")

    total_time = flatten_time + destroy_time + upsert_time + delete_time
    Logger.info("ChildrenUpserter: Total time #{total_time}ms")

    {:ok, %{created: upsert_count, updated: 0, deleted: delete_count}}
  end

  # ---------------------------------------------------------------------------
  # Flatten parent→children
  # ---------------------------------------------------------------------------

  defp flatten_children(records, attributes, opts) do
    parent_key = Keyword.fetch!(opts, :parent_key)
    id_field = Keyword.fetch!(opts, :id_field)
    relationship_key = Keyword.fetch!(opts, :relationship_key)
    deleted_key = Keyword.get(opts, :deleted_key)
    source_file_id = Keyword.get(opts, :source_file_id)
    has_source_file_ids = Keyword.get(opts, :has_source_file_ids, false)

    Enum.reduce(records, {[], []}, fn record, {upserts, deletes} ->
      parent_id = record.id
      children = Map.get(record, relationship_key, [])
      explicit_deletes = if deleted_key, do: Map.get(record, deleted_key, []), else: []

      prepared =
        Enum.map(children, fn child ->
          child
          |> Map.put(parent_key, parent_id)
          |> then(fn r ->
            if has_source_file_ids do
              r
              |> Map.put(:source_file_ids, [source_file_id])
              |> Map.put(:flags, [])
            else
              r
            end
          end)
          |> Upsert.prepare_record(attributes, source_file_id: source_file_id)
        end)

      delete_keys =
        Enum.map(explicit_deletes, fn del ->
          {Map.get(del, id_field), parent_id}
        end)

      {prepared ++ upserts, delete_keys ++ deletes}
    end)
  end

  # ---------------------------------------------------------------------------
  # on_missing: :destroy — find keys present in DB but absent from import
  # ---------------------------------------------------------------------------

  defp find_missing_keys(records, all_upserts, table, id_field, parent_key) do
    parent_ids = Enum.map(records, & &1.id)

    incoming_keys =
      MapSet.new(all_upserts, fn row -> {row[id_field], row[parent_key]} end)

    existing_keys =
      from(r in table,
        where: field(r, ^parent_key) in ^parent_ids,
        select: {field(r, ^id_field), field(r, ^parent_key)}
      )
      |> Repo.all()
      |> MapSet.new()

    MapSet.difference(existing_keys, incoming_keys)
    |> MapSet.to_list()
  end

  # ---------------------------------------------------------------------------
  # Deletes
  # ---------------------------------------------------------------------------

  defp execute_deletes([], _table, _id_field, _parent_key), do: 0

  defp execute_deletes(delete_keys, table, id_field, parent_key) do
    delete_keys
    |> Enum.chunk_every(500)
    |> Enum.reduce(0, fn batch, count ->
      {deleted, _} =
        Enum.reduce(batch, from(r in table), fn {id, parent_id}, query ->
          or_where(
            query,
            [r],
            field(r, ^id_field) == ^id and field(r, ^parent_key) == ^parent_id
          )
        end)
        |> Repo.delete_all()

      count + deleted
    end)
  end
end
