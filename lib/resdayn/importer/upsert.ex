defmodule Resdayn.Importer.Upsert do
  @moduledoc """
  Shared primitives for bulk upserting Ash resources into PostgreSQL.

  Handles two concerns:

  1. **Record preparation** — casting and dumping values through Ash's type system
     so that raw parsed maps become database-ready.
  2. **SQL execution** — batched `INSERT ... ON CONFLICT DO UPDATE` with proper
     `source_file_ids` array merging.

  Used by `RecordUpserter` (top-level records) and `ChildrenUpserter` (child/relationship
  records). Not called directly by importer record modules.
  """

  alias Resdayn.Repo

  @batch_size 1000

  # ---------------------------------------------------------------------------
  # Record preparation
  # ---------------------------------------------------------------------------

  @doc """
  Prepare a single record map for database insertion.

  Iterates the given Ash attribute metadata, casting and dumping each value
  present in `record`. Missing attributes are handled as follows:

  - `:source_file_ids` — set to `[source_file_id]` from opts
  - Attributes with a default — evaluate and dump the default
  - Attributes that allow nil — omitted (database default / NULL)
  - Required attributes without a value — omitted (let the database raise)

  ## Options

  - `:source_file_id` — the filename being imported (e.g. `"Morrowind.esm"`)
  """
  def prepare_record(record, attributes, opts \\ []) do
    source_file_id = Keyword.get(opts, :source_file_id)

    Enum.reduce(attributes, %{}, fn attr, acc ->
      case Map.fetch(record, attr.name) do
        {:ok, nil} ->
          # Explicitly nil — skip cast_and_dump, treat as missing
          handle_missing_attribute(attr, acc, source_file_id)

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

  @doc """
  Cast a value through `Ash.Type.cast_input` then `Ash.Type.dump_to_native`.
  """
  def cast_and_dump(attr, value) do
    with {:ok, casted} <- Ash.Type.cast_input(attr.type, value, attr.constraints),
         {:ok, dumped} <- Ash.Type.dump_to_native(attr.type, casted, attr.constraints) do
      {:ok, dumped}
    end
  end

  defp handle_missing_attribute(attr, acc, source_file_id) do
    cond do
      attr.name == :source_file_ids ->
        Map.put(acc, :source_file_ids, [source_file_id])

      attr.default != nil ->
        default_value =
          case attr.default do
            fun when is_function(fun, 0) -> fun.()
            value -> value
          end

        case Ash.Type.dump_to_native(attr.type, default_value, attr.constraints) do
          {:ok, dumped} -> Map.put(acc, attr.name, dumped)
          {:error, _} -> Map.put(acc, attr.name, default_value)
        end

      attr.allow_nil? ->
        acc

      true ->
        acc
    end
  end

  # ---------------------------------------------------------------------------
  # SQL execution
  # ---------------------------------------------------------------------------

  @doc """
  Execute batched upserts for a list of prepared record maps.

  Returns the total number of affected rows.

  ## Options (required)

  - `:table` — PostgreSQL table name (string)
  - `:conflict_keys` — list of atom column names for ON CONFLICT
  - `:source_file_id` — for source_file_ids CASE merging (or nil)
  - `:has_source_file_ids` — boolean, whether the table has that column
  """
  def execute(records, opts) when is_list(records) do
    if records == [] do
      0
    else
      table = Keyword.fetch!(opts, :table)
      conflict_keys = Keyword.fetch!(opts, :conflict_keys)
      source_file_id = Keyword.get(opts, :source_file_id)
      has_source_file_ids = Keyword.get(opts, :has_source_file_ids, false)

      columns = collect_columns(records)

      update_columns =
        columns
        |> Enum.reject(&(&1 in conflict_keys or &1 == :source_file_ids))

      records
      |> Enum.chunk_every(@batch_size)
      |> Enum.reduce(0, fn batch, total ->
        count =
          upsert_batch(batch, table, columns, conflict_keys, update_columns,
            source_file_id: source_file_id,
            has_source_file_ids: has_source_file_ids
          )

        total + count
      end)
    end
  end

  # Collect the full sorted column set across all records (some may have optional fields).
  defp collect_columns(records) do
    records
    |> Enum.flat_map(&Map.keys/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  # ---------------------------------------------------------------------------
  # SQL building and execution for a single batch
  # ---------------------------------------------------------------------------

  defp upsert_batch(batch, table, columns, conflict_keys, update_columns, opts) do
    source_file_id = Keyword.get(opts, :source_file_id)
    has_source_file_ids = Keyword.get(opts, :has_source_file_ids, false)

    num_columns = length(columns)
    num_rows = length(batch)

    placeholders = build_placeholders(num_rows, num_columns)
    column_list = build_column_list(columns)
    conflict_list = build_column_list(conflict_keys)

    {set_clause, params} =
      build_set_clause_and_params(
        batch,
        columns,
        update_columns,
        table,
        num_rows * num_columns,
        source_file_id: source_file_id,
        has_source_file_ids: has_source_file_ids
      )

    sql = build_upsert_sql(table, column_list, placeholders, conflict_list, set_clause)

    result = Repo.query!(sql, params)
    result.num_rows
  end

  # ($1, $2, $3), ($4, $5, $6), ...
  defp build_placeholders(num_rows, num_columns) do
    for row_idx <- 0..(num_rows - 1) do
      row =
        for col_idx <- 0..(num_columns - 1) do
          "$#{row_idx * num_columns + col_idx + 1}"
        end

      "(#{Enum.join(row, ", ")})"
    end
    |> Enum.join(", ")
  end

  # "col1", "col2", "col3"
  defp build_column_list(columns) do
    columns |> Enum.map(&"\"#{&1}\"") |> Enum.join(", ")
  end

  # Returns {set_clause_string, params_list}
  defp build_set_clause_and_params(
         batch,
         columns,
         update_columns,
         table,
         base_param_count,
         opts
       ) do
    source_file_id = Keyword.get(opts, :source_file_id)
    has_source_file_ids = Keyword.get(opts, :has_source_file_ids, false)

    regular_sets =
      Enum.map(update_columns, fn col ->
        "\"#{col}\" = EXCLUDED.\"#{col}\""
      end)

    base_params =
      Enum.flat_map(batch, fn row ->
        Enum.map(columns, fn col -> Map.get(row, col) end)
      end)

    if has_source_file_ids do
      source_file_set =
        "\"source_file_ids\" = CASE " <>
          "WHEN $#{base_param_count + 1} = ANY(\"#{table}\".\"source_file_ids\") " <>
          "THEN \"#{table}\".\"source_file_ids\" " <>
          "ELSE \"#{table}\".\"source_file_ids\" || EXCLUDED.\"source_file_ids\" " <>
          "END"

      clause = Enum.join(regular_sets ++ [source_file_set], ", ")
      {clause, base_params ++ [source_file_id]}
    else
      {Enum.join(regular_sets, ", "), base_params}
    end
  end

  defp build_upsert_sql(table, column_list, placeholders, conflict_list, set_clause) do
    if set_clause == "" do
      """
      INSERT INTO "#{table}" (#{column_list})
      VALUES #{placeholders}
      ON CONFLICT (#{conflict_list}) DO NOTHING
      """
    else
      """
      INSERT INTO "#{table}" (#{column_list})
      VALUES #{placeholders}
      ON CONFLICT (#{conflict_list})
      DO UPDATE SET #{set_clause}
      """
    end
  end
end
