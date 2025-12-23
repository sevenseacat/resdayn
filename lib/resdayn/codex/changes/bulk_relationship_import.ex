defmodule Resdayn.Codex.Changes.BulkRelationshipImport do
  @moduledoc """
  Efficiently imports relationships in bulk across multiple parents using raw Ecto upserts.

  Processes ALL relationships across ALL parents in a single pass using
  PostgreSQL's `INSERT ... ON CONFLICT DO UPDATE` (upsert).

  ## Performance

  For 316,000 cell references across 2,500 cells: ~8-9 seconds (~35,000 records/sec)

  ## How it works

  1. Flatten all relationships with parent keys
  2. Use Ecto's `insert_all` with custom ON CONFLICT handling
  3. Source file IDs are properly merged (appended, not replaced) using PostgreSQL array functions
  4. Handle explicit deletes separately

  ## Options

  * `:parent_resource` - The parent resource module (e.g., Cell)
  * `:related_resource` - The relationship resource module (e.g., CellReference)
  * `:parent_key` - Foreign key field linking to parent (e.g., :cell_id)
  * `:id_field` - Unique identifier field within parent scope (default: :id)
  * `:relationship_key` - Key in records containing new relationships (default: :relationships)
  * `:deleted_key` - Key in records containing deleted relationship IDs (optional)
  * `:on_missing` - What to do with existing records not in new data:
    - `:ignore` - Keep them (for cross-file additive relationships like CellReference)
    - `:destroy` - Delete them (for replacement relationships like inventory)
  * `:source_file_id` - The source file being imported (for tracking)
  """

  require Logger
  alias Resdayn.Repo
  import Ecto.Query

  @doc """
  Import relationships in bulk using raw Ecto upserts with source file merging.

  Returns `{:ok, stats}` where stats contains :created, :updated, :deleted counts.
  """
  def import(records, opts) do
    related_resource = Keyword.fetch!(opts, :related_resource)
    parent_key = Keyword.fetch!(opts, :parent_key)
    id_field = Keyword.get(opts, :id_field, :id)
    relationship_key = Keyword.get(opts, :relationship_key, :relationships)
    deleted_key = Keyword.get(opts, :deleted_key)
    on_missing = Keyword.get(opts, :on_missing, :ignore)
    source_file_id = Keyword.get(opts, :source_file_id)

    table_name = AshPostgres.DataLayer.Info.table(related_resource)
    attributes = Ash.Resource.Info.attributes(related_resource)
    has_source_file_ids = Enum.any?(attributes, &(&1.name == :source_file_ids))

    # Flatten all relationships with parent keys
    {flatten_time, {all_upserts, all_deletes}} =
      :timer.tc(
        fn ->
          Enum.reduce(records, {[], []}, fn record, {upserts, deletes} ->
            parent_id = record.id
            new_relationships = Map.get(record, relationship_key, [])
            explicit_deletes = if deleted_key, do: Map.get(record, deleted_key, []), else: []

            # Prepare records for upsert
            prepared =
              new_relationships
              |> Enum.map(fn rel ->
                rel
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
                |> prepare_for_insert(related_resource)
              end)

            # Collect explicit deletes as {id, parent_id} tuples
            delete_keys =
              explicit_deletes
              |> Enum.map(fn del ->
                {Map.get(del, id_field), parent_id}
              end)

            {upserts ++ prepared, deletes ++ delete_keys}
          end)
        end,
        :millisecond
      )

    Logger.debug(
      "BulkRelationshipImport: Flattened #{length(all_upserts)} upserts, #{length(all_deletes)} deletes in #{flatten_time}ms"
    )

    # Handle on_missing: :destroy by querying existing IDs first
    {destroy_time, missing_deletes} =
      if on_missing == :destroy do
        :timer.tc(
          fn ->
            parent_ids = Enum.map(records, & &1.id)

            incoming_keys =
              MapSet.new(all_upserts, fn row -> {row[id_field], row[parent_key]} end)

            # Query only the composite keys, not full records
            existing_keys =
              from(r in table_name,
                where: field(r, ^parent_key) in ^parent_ids,
                select: {field(r, ^id_field), field(r, ^parent_key)}
              )
              |> Repo.all()
              |> MapSet.new()

            # Find keys to delete
            MapSet.difference(existing_keys, incoming_keys)
            |> MapSet.to_list()
          end,
          :millisecond
        )
      else
        {0, []}
      end

    if on_missing == :destroy do
      Logger.debug(
        "BulkRelationshipImport: Found #{length(missing_deletes)} missing records to delete in #{destroy_time}ms"
      )
    end

    total_deletes = all_deletes ++ missing_deletes

    # Execute upserts using raw Ecto with source file merging
    {upsert_time, upsert_count} =
      :timer.tc(
        fn ->
          execute_upserts(
            all_upserts,
            table_name,
            id_field,
            parent_key,
            source_file_id,
            has_source_file_ids
          )
        end,
        :millisecond
      )

    Logger.debug("BulkRelationshipImport: Upserted #{upsert_count} records in #{upsert_time}ms")

    # Execute deletes
    {delete_time, delete_count} =
      :timer.tc(
        fn ->
          execute_deletes(total_deletes, table_name, id_field, parent_key)
        end,
        :millisecond
      )

    Logger.debug("BulkRelationshipImport: Deleted #{delete_count} records in #{delete_time}ms")

    total_time = flatten_time + destroy_time + upsert_time + delete_time
    Logger.debug("BulkRelationshipImport: Total time #{total_time}ms")

    {:ok,
     %{
       created: upsert_count,
       updated: 0,
       deleted: delete_count
     }}
  end

  # Prepare a map for Ecto insert_all by extracting relevant fields with proper type casting
  defp prepare_for_insert(record, resource) do
    attributes = Ash.Resource.Info.attributes(resource)
    relationships = Ash.Resource.Info.relationships(resource)

    # Build the row from attributes with proper Ash type casting/dumping
    row =
      Enum.reduce(attributes, %{}, fn attr, acc ->
        value = Map.get(record, attr.name)

        cond do
          value != nil ->
            case cast_and_dump(attr, value) do
              {:ok, dumped} ->
                Map.put(acc, attr.name, dumped)

              {:error, _reason} ->
                # Fall back to raw value if casting fails
                Map.put(acc, attr.name, value)
            end

          attr.default != nil and not attr.allow_nil? ->
            default_value =
              case attr.default do
                fun when is_function(fun, 0) -> fun.()
                val -> val
              end

            case Ash.Type.dump_to_native(attr.type, default_value, attr.constraints) do
              {:ok, dumped} -> Map.put(acc, attr.name, dumped)
              {:error, _} -> Map.put(acc, attr.name, default_value)
            end

          true ->
            acc
        end
      end)

    # Add belongs_to foreign keys
    Enum.reduce(relationships, row, fn rel, acc ->
      if rel.type == :belongs_to do
        value = Map.get(record, rel.source_attribute)

        if value != nil do
          Map.put(acc, rel.source_attribute, value)
        else
          acc
        end
      else
        acc
      end
    end)
  end

  defp cast_and_dump(attr, value) do
    with {:ok, casted} <- Ash.Type.cast_input(attr.type, value, attr.constraints),
         {:ok, dumped} <- Ash.Type.dump_to_native(attr.type, casted, attr.constraints) do
      {:ok, dumped}
    end
  end

  defp execute_upserts([], _table, _id_field, _parent_key, _source_file_id, _has_source_file_ids),
    do: 0

  defp execute_upserts(
         records,
         table,
         id_field,
         parent_key,
         source_file_id,
         has_source_file_ids
       ) do
    # Get column names from ALL records (some may have optional fields others don't)
    # Exclude primary keys and source_file_ids from the update clause
    replace_columns =
      records
      |> Enum.flat_map(&Map.keys/1)
      |> Enum.uniq()
      |> Enum.reject(&(&1 == id_field or &1 == parent_key or &1 == :source_file_ids))

    # Chunk to avoid parameter limits (PostgreSQL has a limit of ~32767 parameters)
    # With ~20 columns per row, we can do ~1500 rows per batch
    records
    |> Enum.chunk_every(1000)
    |> Enum.reduce(0, fn batch, count ->
      # Use raw SQL for the upsert with proper source_file_ids merging
      {inserted, _} =
        execute_upsert_batch(
          batch,
          table,
          id_field,
          parent_key,
          replace_columns,
          source_file_id,
          has_source_file_ids
        )

      count + inserted
    end)
  end

  defp execute_upsert_batch(
         batch,
         table,
         id_field,
         parent_key,
         replace_columns,
         source_file_id,
         has_source_file_ids
       ) do
    # Get all column names from ALL records in the batch (some may have optional fields others don't)
    columns =
      batch
      |> Enum.flat_map(&Map.keys/1)
      |> Enum.uniq()
      |> Enum.sort()

    # Build the VALUES placeholders
    num_columns = length(columns)
    num_rows = length(batch)

    placeholders =
      for row_idx <- 0..(num_rows - 1) do
        row_placeholders =
          for col_idx <- 0..(num_columns - 1) do
            "$#{row_idx * num_columns + col_idx + 1}"
          end

        "(#{Enum.join(row_placeholders, ", ")})"
      end
      |> Enum.join(", ")

    # Build the column list
    column_list = columns |> Enum.map(&"\"#{&1}\"") |> Enum.join(", ")

    # Build the SET clause for ON CONFLICT
    # Regular columns just use EXCLUDED.column
    set_clauses =
      Enum.map(replace_columns, fn col ->
        "\"#{col}\" = EXCLUDED.\"#{col}\""
      end)

    # Build final SET clauses and params based on whether resource has source_file_ids
    {all_set_clauses, params} =
      if has_source_file_ids do
        # Source file merging: append if not already present
        source_file_set =
          """
          "source_file_ids" = CASE
            WHEN $#{num_rows * num_columns + 1} = ANY("#{table}"."source_file_ids")
            THEN "#{table}"."source_file_ids"
            ELSE "#{table}"."source_file_ids" || EXCLUDED."source_file_ids"
          END
          """

        clauses = Enum.join(set_clauses ++ [source_file_set], ", ")

        # Build the params list - flatten batch values in column order, then add source_file_id
        params =
          Enum.flat_map(batch, fn row ->
            Enum.map(columns, fn col -> Map.get(row, col) end)
          end) ++ [source_file_id]

        {clauses, params}
      else
        # No source_file_ids - just use regular update columns
        clauses = Enum.join(set_clauses, ", ")

        # Build the params list - flatten batch values in column order only
        params =
          Enum.flat_map(batch, fn row ->
            Enum.map(columns, fn col -> Map.get(row, col) end)
          end)

        {clauses, params}
      end

    # Handle case where there's nothing to update (only conflict keys)
    sql =
      if all_set_clauses == "" do
        """
        INSERT INTO "#{table}" (#{column_list})
        VALUES #{placeholders}
        ON CONFLICT ("#{id_field}", "#{parent_key}") DO NOTHING
        """
      else
        """
        INSERT INTO "#{table}" (#{column_list})
        VALUES #{placeholders}
        ON CONFLICT ("#{id_field}", "#{parent_key}")
        DO UPDATE SET #{all_set_clauses}
        """
      end

    Repo.query!(sql, params)
    |> then(fn result -> {result.num_rows, nil} end)
  end

  defp execute_deletes([], _table, _id_field, _parent_key), do: 0

  defp execute_deletes(delete_keys, table, id_field, parent_key) do
    # Delete in batches using OR conditions for composite keys
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
