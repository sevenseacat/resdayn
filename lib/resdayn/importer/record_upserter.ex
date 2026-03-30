defmodule Resdayn.Importer.RecordUpserter do
  @moduledoc """
  Bulk upsert top-level Ash resources (NPCs, Cells, Spells, etc.).

  Each record has a simple primary key (e.g. `:id`). For resources with the
  `Referencable` extension, the corresponding `referencable_objects` row is
  upserted first.

  Delegates record preparation and SQL execution to `Resdayn.Importer.Upsert`.
  """

  require Logger

  alias Resdayn.Repo
  alias Resdayn.Importer.Upsert

  @doc """
  Import records in bulk.

  Returns `{:ok, %{total: count}}` on success.

  ## Options

  - `:source_file_id` — the filename being imported (for tracking)
  - `:conflict_keys` — columns for ON CONFLICT (default: `[:id]`)
  """
  def import(records, resource, opts \\ []) do
    if Enum.empty?(records) do
      {:ok, %{total: 0, inserted: 0, updated: 0}}
    else
      table = AshPostgres.DataLayer.Info.table(resource)
      attributes = Ash.Resource.Info.attributes(resource)
      conflict_keys = Keyword.get(opts, :conflict_keys, [:id])
      source_file_id = Keyword.get(opts, :source_file_id)
      has_source_file_ids = Enum.any?(attributes, &(&1.name == :source_file_ids))

      referencable_type = get_referencable_type(resource)

      if referencable_type do
        upsert_referencable_objects(records, referencable_type)
      end

      {prepare_time, prepared} =
        :timer.tc(
          fn ->
            Enum.map(records, &Upsert.prepare_record(&1, attributes, source_file_id: source_file_id))
          end,
          :millisecond
        )

      Logger.info("RecordUpserter: Prepared #{length(prepared)} records in #{prepare_time}ms")

      {upsert_time, total} =
        :timer.tc(
          fn ->
            Upsert.execute(prepared,
              table: table,
              conflict_keys: conflict_keys,
              source_file_id: source_file_id,
              has_source_file_ids: has_source_file_ids
            )
          end,
          :millisecond
        )

      Logger.info("RecordUpserter: Upserted #{total} records in #{upsert_time}ms")

      {:ok, %{total: total}}
    end
  end

  @doc """
  Prepare a single record for database insertion.

  Delegates to `Upsert.prepare_record/3`. Exposed for testing.
  """
  def prepare_record(record, attributes, source_file_id) do
    Upsert.prepare_record(record, attributes, source_file_id: source_file_id)
  end

  # ---------------------------------------------------------------------------
  # Referencable object handling
  # ---------------------------------------------------------------------------

  @doc false
  def get_referencable_type(resource) do
    extensions = Spark.extensions(resource)

    if Resdayn.Codex.Referencable in extensions do
      Resdayn.Codex.World.ReferencableObject.Type.resource_to_type(resource)
    else
      nil
    end
  end

  @doc false
  def upsert_referencable_objects(records, object_type) do
    ref_records =
      Enum.map(records, fn record ->
        %{id: record.id, type: Atom.to_string(object_type)}
      end)

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

    Logger.info(
      "RecordUpserter: Upserted #{length(ref_records)} referencable_objects (type: #{object_type})"
    )
  end
end
