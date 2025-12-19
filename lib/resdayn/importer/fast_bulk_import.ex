defmodule Resdayn.Importer.FastBulkImport do
  @moduledoc """
  Fast bulk import using direct Ecto operations with Ash type casting/dumping.

  Bypasses Ash changeset overhead while maintaining type safety by:
  1. Using `Ash.Type.cast_input` to validate and normalize values
  2. Using `Ash.Type.dump_to_native` to convert to database format
  3. Using raw Ecto `insert_all` with ON CONFLICT for upserts

  This achieves ~35,000 records/sec vs ~5-18,000 with Ash bulk_create.

  ## Usage

      FastBulkImport.import(records, MyResource, source_file_id: "Morrowind.esm")

  ## Options

  * `:source_file_id` - The source file being imported (for tracking)
  * `:conflict_keys` - Keys to use for ON CONFLICT (default: `[:id]`)

  ## Referencable Resources

  Resources with the `Resdayn.Codex.Referencable` extension require a corresponding
  entry in the `referencable_objects` table. This module automatically detects
  Referencable resources and bulk inserts into `referencable_objects` first.
  """

  require Logger
  alias Resdayn.Repo

  @doc """
  Import records in bulk using raw Ecto upserts with proper Ash type handling.

  Returns `{:ok, %{total: count}}` on success.
  """
  def import(records, resource, opts \\ []) do
    if Enum.empty?(records) do
      {:ok, %{total: 0, inserted: 0, updated: 0}}
    else
      table = AshPostgres.DataLayer.Info.table(resource)
      attributes = Ash.Resource.Info.attributes(resource)
      conflict_keys = Keyword.get(opts, :conflict_keys, [:id])
      source_file_id = Keyword.get(opts, :source_file_id)

      # Check if this resource uses Referencable extension
      referencable_type = get_referencable_type(resource)

      # If Referencable, insert into referencable_objects first
      if referencable_type do
        upsert_referencable_objects(records, referencable_type)
      end

      # Prepare all records with proper type casting and dumping
      {prepare_time, prepared} =
        :timer.tc(
          fn ->
            Enum.map(records, &prepare_record(&1, attributes, source_file_id))
          end,
          :millisecond
        )

      Logger.debug("FastBulkImport: Prepared #{length(prepared)} records in #{prepare_time}ms")

      # Execute upserts
      {upsert_time, result} =
        :timer.tc(
          fn ->
            execute_upserts(prepared, table, conflict_keys, source_file_id)
          end,
          :millisecond
        )

      Logger.debug("FastBulkImport: Upserted #{result.total} records in #{upsert_time}ms")

      {:ok, result}
    end
  end

  @doc """
  Check if a resource uses the Referencable extension and return its type.

  Returns the referencable type atom (e.g., :sound) or nil if not Referencable.
  """
  def get_referencable_type(resource) do
    extensions = Spark.extensions(resource)

    if Resdayn.Codex.Referencable in extensions do
      Resdayn.Codex.World.ReferencableObject.Type.resource_to_type(resource)
    else
      nil
    end
  end

  @doc """
  Bulk upsert records into referencable_objects table.
  """
  def upsert_referencable_objects(records, object_type) do
    # Prepare referencable object records
    ref_records =
      Enum.map(records, fn record ->
        %{id: record.id, type: Atom.to_string(object_type)}
      end)

    # Chunk and upsert
    ref_records
    |> Enum.chunk_every(1000)
    |> Enum.each(fn batch ->
      num_rows = length(batch)

      placeholders =
        for row_idx <- 0..(num_rows - 1) do
          "($#{row_idx * 2 + 1}, $#{row_idx * 2 + 2})"
        end
        |> Enum.join(", ")

      sql = """
      INSERT INTO "referencable_objects" ("id", "type")
      VALUES #{placeholders}
      ON CONFLICT ("id") DO UPDATE SET "type" = EXCLUDED."type"
      """

      params =
        Enum.flat_map(batch, fn row ->
          [row.id, row.type]
        end)

      Repo.query!(sql, params)
    end)

    Logger.debug(
      "FastBulkImport: Upserted #{length(ref_records)} referencable_objects (type: #{object_type})"
    )
  end

  @doc """
  Prepare a single record for database insertion.

  Casts and dumps all attribute values using Ash types.
  """
  def prepare_record(record, attributes, source_file_id) do
    Enum.reduce(attributes, %{}, fn attr, acc ->
      case Map.fetch(record, attr.name) do
        {:ok, value} ->
          case cast_and_dump(attr, value) do
            {:ok, dumped} ->
              Map.put(acc, attr.name, dumped)

            {:error, reason} ->
              raise "Failed to cast/dump #{attr.name}: #{inspect(reason)}, value: #{inspect(value)}"
          end

        :error ->
          handle_missing_attribute(attr, acc, source_file_id)
      end
    end)
  end

  defp cast_and_dump(attr, value) do
    with {:ok, casted} <- Ash.Type.cast_input(attr.type, value, attr.constraints),
         {:ok, dumped} <- Ash.Type.dump_to_native(attr.type, casted, attr.constraints) do
      {:ok, dumped}
    end
  end

  defp handle_missing_attribute(attr, acc, source_file_id) do
    cond do
      # source_file_ids is handled specially - always set from source_file_id param
      attr.name == :source_file_ids ->
        Map.put(acc, :source_file_ids, [source_file_id])

      # Use default if available
      attr.default != nil ->
        default_value =
          case attr.default do
            fun when is_function(fun, 0) -> fun.()
            value -> value
          end

        case Ash.Type.dump_to_native(attr.type, default_value, attr.constraints) do
          {:ok, dumped} -> Map.put(acc, attr.name, dumped)
          # Use raw default if dump fails
          {:error, _} -> Map.put(acc, attr.name, default_value)
        end

      # Allow nil if permitted
      attr.allow_nil? ->
        acc

      # Required field missing - let database handle the error
      true ->
        acc
    end
  end

  defp execute_upserts(records, table, conflict_keys, source_file_id) do
    # Get column names from ALL records (some records may have optional fields others don't)
    columns =
      records
      |> Enum.flat_map(&Map.keys/1)
      |> Enum.uniq()
      |> Enum.sort()

    # Columns to update on conflict (excluding primary keys and source_file_ids)
    update_columns =
      columns
      |> Enum.reject(&(&1 in conflict_keys or &1 == :source_file_ids))

    # Chunk to avoid parameter limits (~32767 params in PostgreSQL)
    # With ~20 columns, ~1500 rows per batch is safe
    chunk_size = 1000

    records
    |> Enum.chunk_every(chunk_size)
    |> Enum.reduce(%{total: 0}, fn batch, acc ->
      count =
        execute_upsert_batch(batch, table, columns, conflict_keys, update_columns, source_file_id)

      %{total: acc.total + count}
    end)
  end

  defp execute_upsert_batch(batch, table, columns, conflict_keys, update_columns, source_file_id) do
    num_columns = length(columns)
    num_rows = length(batch)

    # Build placeholders: ($1, $2, ...), ($n+1, $n+2, ...), ...
    placeholders =
      for row_idx <- 0..(num_rows - 1) do
        row_placeholders =
          for col_idx <- 0..(num_columns - 1) do
            "$#{row_idx * num_columns + col_idx + 1}"
          end

        "(#{Enum.join(row_placeholders, ", ")})"
      end
      |> Enum.join(", ")

    # Build column list
    column_list = columns |> Enum.map(&"\"#{&1}\"") |> Enum.join(", ")

    # Build conflict keys
    conflict_list = conflict_keys |> Enum.map(&"\"#{&1}\"") |> Enum.join(", ")

    # Build SET clause for regular columns
    set_clauses =
      Enum.map(update_columns, fn col ->
        "\"#{col}\" = EXCLUDED.\"#{col}\""
      end)

    # Source file merging: append if not already present
    # The extra parameter ($n+1) is the source_file_id for the CASE check
    param_num = num_rows * num_columns + 1

    source_file_set =
      "\"source_file_ids\" = CASE " <>
        "WHEN $#{param_num} = ANY(\"#{table}\".\"source_file_ids\") " <>
        "THEN \"#{table}\".\"source_file_ids\" " <>
        "ELSE \"#{table}\".\"source_file_ids\" || EXCLUDED.\"source_file_ids\" " <>
        "END"

    all_set_clauses = Enum.join(set_clauses ++ [source_file_set], ", ")

    sql = """
    INSERT INTO "#{table}" (#{column_list})
    VALUES #{placeholders}
    ON CONFLICT (#{conflict_list})
    DO UPDATE SET #{all_set_clauses}
    """

    # Build params: flatten batch values in column order, then add source_file_id
    params =
      Enum.flat_map(batch, fn row ->
        Enum.map(columns, fn col -> Map.get(row, col) end)
      end) ++ [source_file_id]

    result = Repo.query!(sql, params)
    result.num_rows
  end
end
