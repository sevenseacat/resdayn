defmodule Resdayn.Codex.Changes.OptimizedRelationshipImport do
  @moduledoc """
  A change module that efficiently imports relationships by pre-filtering creates vs updates.

  This optimization avoids the O(n*m) complexity of manage_relationship with direct_control
  by splitting the work into separate bulk operations, resulting in significant performance
  improvements (8x+ speedup observed in practice).

  ## How it works

  1. Queries existing related records for the parent once upfront
  2. Splits incoming data into creates vs potential updates
  3. Filters updates to only records with actual changes
  4. Uses bulk_create! for new records (very efficient)
  5. Uses individual update! calls only for changed records

  This reduces complexity from O(n*m) to O(n+m) where n=incoming records, m=existing records.

  ## Options

  * `:argument` - The name of the argument containing the relationship data (required)
  * `:relationship` - The name of the relationship to manage (required)
  * `:related_resource` - The resource module for the related records (required)
  * `:parent_key` - The foreign key field that links to the parent record (required)
  * `:id_field` - The field to use as the unique identifier (defaults to :id)
  * `:on_missing` - What to do with existing records not in the new data (defaults to :destroy)
    - `:destroy` - Delete records not present in new data (typical for inventory)
    - `:ignore` - Keep existing records not present in new data (typical for references)

  ## Examples

  ### Cell References Import (keep missing records)

  Cell references should be kept even if not in the new data (they may come from other mods):

      update :import_relationships do
        require_atomic? false
        argument :new_references, {:array, :map}, allow_nil?: false

        change {OptimizedRelationshipImport,
          argument: :new_references,
          relationship: :references,
          related_resource: MyApp.CellReference,
          parent_key: :cell_id,
          on_missing: :ignore
        }
      end

  ### NPC Inventory Import (replace all items)

  Inventory should be completely replaced - if an item isn't in the new data, it should be removed:

      update :import_inventory do
        require_atomic? false
        argument :new_items, {:array, :map}, allow_nil?: false

        change {OptimizedRelationshipImport,
          argument: :new_items,
          relationship: :inventory_items,
          related_resource: MyApp.InventoryItem,
          parent_key: :npc_id,
          on_missing: :destroy
        }
      end

  ### Container Items Import (replace all contents)

  Container contents should also be completely replaced:

      update :import_contents do
        require_atomic? false
        argument :new_contents, {:array, :map}, allow_nil?: false

        change {OptimizedRelationshipImport,
          argument: :new_contents,
          relationship: :contained_items,
          related_resource: MyApp.ContainerItem,
          parent_key: :container_id,
          on_missing: :destroy
        }
      end

  ## Data Format

  The argument data should be an array of maps where each map contains:
  - The ID field (typically `:id`)
  - The foreign key field (will be set automatically)
  - All other fields that should be created/updated

  Example data:

      [
        %{
          id: 1,
          reference_id: "some_object",
          count: 5,
          coordinates: %{position: %{x: 100, y: 200, z: 300}}
        },
        %{
          id: 2,
          reference_id: "another_object",
          count: 1,
          scale: 1.5
        }
      ]

  The change will automatically:
  - Add the parent key (e.g., `cell_id: "1,2"`) to each record
  - Compare all fields except `:id` and the parent key to detect changes
  - Only perform database operations for records that actually need them
  """

  use Ash.Resource.Change
  require Ash.Query

  @impl true
  def init(opts) do
    required_keys = [:argument, :relationship, :related_resource, :parent_key]

    for key <- required_keys do
      unless Keyword.has_key?(opts, key) do
        raise ArgumentError, "#{key} is required for OptimizedRelationshipImport"
      end
    end

    opts =
      opts
      |> Keyword.put_new(:id_field, :id)
      |> Keyword.put_new(:on_missing, :destroy)

    {:ok, opts}
  end

  @impl true
  def change(changeset, opts, _context) do
    argument_name = opts[:argument]
    related_resource = opts[:related_resource]
    parent_key = opts[:parent_key]
    id_field = opts[:id_field]
    on_missing = opts[:on_missing]

    parent_id = Ash.Changeset.get_attribute(changeset, :id)
    new_records = Ash.Changeset.get_argument(changeset, argument_name)

    if is_nil(parent_id) or is_nil(new_records) or Enum.empty?(new_records) do
      changeset
    else
      # Auto-detect compare fields from the first record (all fields except id and parent key)
      compare_fields =
        case new_records do
          [first_record | _] ->
            first_record
            |> Map.keys()
            |> Enum.reject(&(&1 == id_field or &1 == parent_key))

          [] ->
            []
        end

      perform_optimized_import(
        changeset,
        parent_id,
        new_records,
        related_resource,
        parent_key,
        compare_fields,
        id_field,
        on_missing
      )
    end
  end

  defp perform_optimized_import(
         changeset,
         parent_id,
         new_records,
         related_resource,
         parent_key,
         compare_fields,
         id_field,
         on_missing
       ) do
    # Get existing records for this parent
    existing_records =
      related_resource
      |> Ash.Query.filter(^ref(parent_key) == ^parent_id)
      |> Ash.read!(authorize?: false)
      |> Enum.map(&{Map.get(&1, id_field), &1})
      |> Map.new()

    existing_ids = MapSet.new(Map.keys(existing_records))
    incoming_ids = MapSet.new(Enum.map(new_records, &Map.get(&1, id_field)))

    # Split into creates and potential updates
    {creates, potential_updates} =
      Enum.split_with(new_records, fn record ->
        Map.get(record, id_field) not in existing_ids
      end)

    # Filter updates to only include non-deleted changed records
    actual_updates =
      potential_updates
      |> Enum.reject(& &1[:deleted])
      |> Enum.filter(fn record ->
        existing = existing_records[Map.get(record, id_field)]

        Enum.any?(compare_fields, fn field ->
          Map.get(record, field) != Map.get(existing, field)
        end)
      end)

    # Add parent key to all new records
    creates_with_parent =
      Enum.map(creates, &(Map.put(&1, parent_key, parent_id) |> Map.delete(:deleted)))

    # Perform bulk create for new records
    if not Enum.empty?(creates_with_parent) do
      Ash.bulk_create!(
        creates_with_parent,
        related_resource,
        :create,
        return_errors?: true
      )
    end

    # Perform individual updates for changed records
    Enum.each(actual_updates, fn record ->
      existing_record = existing_records[Map.get(record, id_field)]
      update_data = Map.take(record, compare_fields) |> Map.delete(:deleted)

      Ash.update!(existing_record, update_data, authorize?: false)
    end)

    potential_updates
    |> Enum.filter(& &1[:deleted])
    |> Enum.map(&existing_records[Map.get(&1, id_field)])
    |> Ash.bulk_destroy!(:destroy, %{}, return_records?: true)

    # Handle missing records based on on_missing option
    if on_missing == :destroy do
      missing_ids = MapSet.difference(existing_ids, incoming_ids)

      records_to_delete =
        Enum.filter(Map.values(existing_records), fn record ->
          Map.get(record, id_field) in missing_ids
        end)

      Enum.each(records_to_delete, fn record ->
        Ash.destroy!(record, authorize?: false)
      end)
    end

    changeset
  end
end
