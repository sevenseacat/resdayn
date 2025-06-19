defmodule Resdayn.Importer.SourceTracker do
  @moduledoc """
  Handles source file tracking and event emission for import operations.
  """

  alias Resdayn.Codex.Events.ImportEvent
  alias Resdayn.Codex.Importable

  @doc """
  Adds source file ID to record data for import.
  """
  def add_source_file_id(record_data, source_file_id) when is_map(record_data) do
    current_ids = Map.get(record_data, :source_file_ids, [])

    # Add source file ID if not already present
    updated_ids =
      if source_file_id in current_ids do
        current_ids
      else
        current_ids ++ [source_file_id]
      end

    Map.put(record_data, :source_file_ids, updated_ids)
  end

  def add_source_file_id(record_list, source_file_id) when is_list(record_list) do
    Enum.map(record_list, &add_source_file_id(&1, source_file_id))
  end

  @doc """
  Gets the list of significant attributes for a resource, excluding ignored and tracking attributes.
  """
  def significant_attributes(resource) do
    ignore_attrs = Importable.ignore_attributes(resource)

    Ash.Resource.Info.attributes(resource)
    |> Enum.filter(& &1.writable?)
    |> Enum.map(& &1.name)
    |> Enum.reject(&(&1 in ignore_attrs))
    # Exclude source tracking fields
    |> Enum.reject(&(&1 in [:source_file_ids, :flags]))
  end

  @doc """
  Determines if an update represents a significant change based on the resource's ignore_attributes configuration.
  """
  def significant_change?(resource, existing_record, new_data) do
    attrs = significant_attributes(resource)

    existing_values = Map.take(existing_record, attrs)
    new_values = Map.take(new_data, attrs)

    existing_values != new_values
  end

  @doc """
  Calculates the changeset between existing and new data, respecting ignore_attributes.
  """
  def calculate_changes(resource, existing_record, new_data) do
    attrs = significant_attributes(resource)

    existing_values = Map.take(existing_record, attrs)
    new_values = Map.take(new_data, attrs)

    # Calculate what actually changed
    Enum.reduce(attrs, %{}, fn attr, acc ->
      old_val = Map.get(existing_values, attr)
      new_val = Map.get(new_values, attr)

      if old_val != new_val do
        # Serialize values to make them JSON-safe
        from_serialized = serialize_for_json(old_val)
        to_serialized = serialize_for_json(new_val)
        Map.put(acc, attr, %{from: from_serialized, to: to_serialized})
      else
        acc
      end
    end)
  end

  # Helper function to serialize complex values for JSON storage
  defp serialize_for_json(value) when is_struct(value) do
    value
    |> Map.from_struct()
    |> Map.drop([:__meta__])
    |> serialize_for_json()
  end

  defp serialize_for_json(value) when is_list(value) do
    Enum.map(value, &serialize_for_json/1)
  end

  defp serialize_for_json(value) when is_map(value) do
    value
    |> Enum.map(fn {k, v} -> {k, serialize_for_json(v)} end)
    |> Map.new()
  end

  defp serialize_for_json(%Ash.NotLoaded{}), do: nil
  defp serialize_for_json(value), do: value

  @doc """
  Emits an import event for record creation.
  """
  def emit_create_event(record_id, source_file_id) do
    ImportEvent
    |> Ash.Changeset.for_create(:create, %{
      event_type: :record_created,
      resource_type: "record",
      resource_id: to_string(record_id),
      source_file_id: source_file_id,
      changes: %{}
    })
    |> Ash.create()
  end

  @doc """
  Emits an import event for record update with detailed changes.
  """
  def emit_update_event(record_id, source_file_id, changes) do
    ImportEvent
    |> Ash.Changeset.for_create(:create, %{
      event_type: :record_updated,
      resource_type: "record",
      resource_id: to_string(record_id),
      source_file_id: source_file_id,
      changes: changes
    })
    |> Ash.create()
  end

  @doc """
  Merges source file IDs, ensuring existing IDs are preserved and new ones are added.
  """
  def merge_source_file_ids(existing_source_ids, new_source_ids, current_source_file_id) do
    existing_ids = existing_source_ids || []

    if current_source_file_id in existing_ids do
      existing_ids
    else
      existing_ids ++ new_source_ids
    end
  end

  @doc """
  Processes a create scenario - emits event and returns the record.
  """
  def process_create(record, source_file_id) do
    emit_create_event_async(record.id, source_file_id)
    record
  end

  @doc """
  Processes an update scenario with significant changes.
  """
  def process_significant_update(record, existing_record, resource, source_file_id, update_action) do
    changes = calculate_changes(resource, existing_record, record)
    emit_update_event_async(record.id, source_file_id, changes)

    merged_source_ids =
      merge_source_file_ids(
        existing_record.source_file_ids,
        record.source_file_ids,
        source_file_id
      )

    data = Map.put(record, :source_file_ids, merged_source_ids)
    Ash.Changeset.for_update(existing_record, update_action, Map.drop(data, [:id]))
  end

  @doc """
  Processes an update scenario with no significant changes.
  """
  def process_tracking_update(record, existing_record, source_file_id, update_action) do
    existing_source_ids = existing_record.source_file_ids || []
    is_new_source = source_file_id not in existing_source_ids

    merged_source_ids =
      if is_new_source do
        new_merged_ids = existing_record.source_file_ids ++ record.source_file_ids

        emit_source_tracking_event_async(
          record.id,
          source_file_id,
          existing_source_ids,
          new_merged_ids
        )

        new_merged_ids
      else
        existing_record.source_file_ids
      end

    Ash.Changeset.for_update(existing_record, update_action, %{
      source_file_ids: merged_source_ids
    })
  end

  @doc """
  Async event emission helpers to reduce duplication.
  """
  def emit_create_event_async(record_id, source_file_id) do
    Task.start(fn ->
      case emit_create_event(record_id, source_file_id) do
        {:ok, _event} -> :ok
        {:error, error} -> IO.puts("Error creating event: #{inspect(error)}")
      end
    end)
  end

  def emit_update_event_async(record_id, source_file_id, changes) do
    Task.start(fn ->
      case emit_update_event(record_id, source_file_id, changes) do
        {:ok, _event} -> :ok
        {:error, error} -> IO.puts("Error creating update event: #{inspect(error)}")
      end
    end)
  end

  def emit_source_tracking_event_async(record_id, source_file_id, from_ids, to_ids) do
    Task.start(fn ->
      case emit_update_event(record_id, source_file_id, %{
             source_file_ids: %{from: from_ids, to: to_ids}
           }) do
        {:ok, _event} -> :ok
        {:error, error} -> IO.puts("Error creating source tracking event: #{inspect(error)}")
      end
    end)
  end

  @doc """
  Processes a batch of records for import with source tracking and event emission.

  Returns a map with :create and :update lists, with events emitted for significant changes.
  """
  def process_with_tracking(records, resource, source_file_id, opts \\ []) do
    # Add source file ID to all records
    records_with_source = add_source_file_id(records, source_file_id)

    # Find existing records
    existing = find_existing_records(resource, records_with_source)

    update_action = Keyword.get(opts, :action, :import_update)

    # Separate creates and updates with change detection
    {creates, updates} =
      Enum.reduce(records_with_source, {[], []}, fn record, {creates, updates} ->
        case Map.get(existing, record.id) do
          nil ->
            # New record
            create_record = process_create(record, source_file_id)
            {[create_record | creates], updates}

          existing_record ->
            # Existing record - check if update is significant
            if significant_change?(resource, existing_record, record) do
              changeset =
                process_significant_update(
                  record,
                  existing_record,
                  resource,
                  source_file_id,
                  update_action
                )

              {creates, [changeset | updates]}
            else
              changeset =
                process_tracking_update(record, existing_record, source_file_id, update_action)

              {creates, [changeset | updates]}
            end
        end
      end)

    %{
      resource: resource,
      create: Enum.reverse(creates),
      update: Enum.reverse(updates)
    }
  end

  defp find_existing_records(resource, records) do
    require Ash.Query
    ids = Enum.map(records, & &1.id)

    resource
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(id in ^ids)
    |> Ash.read!()
    |> Map.new(&{&1.id, &1})
  end
end
