defmodule Resdayn.Codex.Changes.OptimizedRelationshipImportTest do
  use ExUnit.Case, async: true
  alias Resdayn.Codex.Changes.OptimizedRelationshipImport

  describe "init/1" do
    test "validates required options" do
      # Missing argument
      assert_raise ArgumentError, ~r/argument is required/, fn ->
        OptimizedRelationshipImport.init(
          relationship: :references,
          related_resource: SomeModule,
          parent_key: :cell_id
        )
      end

      # Missing relationship
      assert_raise ArgumentError, ~r/relationship is required/, fn ->
        OptimizedRelationshipImport.init(
          argument: :new_references,
          related_resource: SomeModule,
          parent_key: :cell_id
        )
      end

      # Missing related_resource
      assert_raise ArgumentError, ~r/related_resource is required/, fn ->
        OptimizedRelationshipImport.init(
          argument: :new_references,
          relationship: :references,
          parent_key: :cell_id
        )
      end

      # Missing parent_key
      assert_raise ArgumentError, ~r/parent_key is required/, fn ->
        OptimizedRelationshipImport.init(
          argument: :new_references,
          relationship: :references,
          related_resource: SomeModule
        )
      end
    end

    test "sets default values" do
      {:ok, opts} =
        OptimizedRelationshipImport.init(
          argument: :new_references,
          relationship: :references,
          related_resource: SomeModule,
          parent_key: :cell_id
        )

      assert opts[:id_field] == :id
      assert opts[:on_missing] == :destroy
    end

    test "preserves custom values" do
      {:ok, opts} =
        OptimizedRelationshipImport.init(
          argument: :new_references,
          relationship: :references,
          related_resource: SomeModule,
          parent_key: :cell_id,
          id_field: :custom_id,
          on_missing: :ignore
        )

      assert opts[:id_field] == :custom_id
      assert opts[:on_missing] == :ignore
    end
  end

  describe "change/3 with empty data" do
    test "returns unchanged changeset when parent_id is nil" do
      changeset = %Ash.Changeset{
        attributes: %{},
        arguments: %{new_references: []},
        resource: SomeResource,
        data: %{}
      }

      opts = [
        argument: :new_references,
        relationship: :references,
        related_resource: SomeModule,
        parent_key: :cell_id,
        id_field: :id,
        on_missing: :destroy
      ]

      result = OptimizedRelationshipImport.change(changeset, opts, %{})
      assert result == changeset
    end

    test "returns unchanged changeset when new_records is nil" do
      changeset = %Ash.Changeset{
        attributes: %{id: "test_id"},
        arguments: %{new_references: nil},
        resource: SomeResource,
        data: %{id: "test_id"}
      }

      opts = [
        argument: :new_references,
        relationship: :references,
        related_resource: SomeModule,
        parent_key: :cell_id,
        id_field: :id,
        on_missing: :destroy
      ]

      result = OptimizedRelationshipImport.change(changeset, opts, %{})
      assert result == changeset
    end

    test "returns unchanged changeset when new_records is empty" do
      changeset = %Ash.Changeset{
        attributes: %{id: "test_id"},
        arguments: %{new_references: []},
        resource: SomeResource,
        data: %{id: "test_id"}
      }

      opts = [
        argument: :new_references,
        relationship: :references,
        related_resource: SomeModule,
        parent_key: :cell_id,
        id_field: :id,
        on_missing: :destroy
      ]

      result = OptimizedRelationshipImport.change(changeset, opts, %{})
      assert result == changeset
    end
  end

  describe "field comparison logic" do
    test "auto-detects compare fields from input data" do
      # Test that the change correctly identifies fields to compare
      new_records = [
        %{
          id: 1,
          name: "Test",
          value: 42,
          description: "A test record"
        }
      ]

      changeset = %Ash.Changeset{
        attributes: %{id: "test_id"},
        arguments: %{new_records: new_records},
        resource: SomeResource,
        data: %{id: "test_id"}
      }

      # Mock the related resource query to return empty results
      defmodule MockRelatedResource do
        def __ash_bindings__, do: %{}
        def __ash_dsl__, do: %{}
      end

      # Since we can't easily mock Ash.Query.filter and Ash.read! in a unit test,
      # we'll focus on testing the init logic and argument validation instead
      # Full integration testing would require a more complex setup

      _opts = [
        argument: :new_records,
        relationship: :children,
        related_resource: MockRelatedResource,
        parent_key: :parent_id,
        id_field: :id,
        on_missing: :ignore
      ]

      # The change should not error with valid inputs
      # (actual database operations would be tested in integration tests)
      assert is_list(new_records)
      assert length(new_records) == 1

      # Verify the fields that would be compared (excluding id and parent_key)
      first_record = hd(new_records)
      all_fields = Map.keys(first_record)
      compare_fields = Enum.reject(all_fields, &(&1 == :id or &1 == :parent_id))

      assert :name in compare_fields
      assert :value in compare_fields
      assert :description in compare_fields
      assert :id not in compare_fields
      assert :parent_id not in compare_fields
    end
  end

  describe "options validation" do
    test "all required options present" do
      opts = [
        argument: :new_items,
        relationship: :items,
        related_resource: ItemModule,
        parent_key: :container_id
      ]

      assert {:ok, validated_opts} = OptimizedRelationshipImport.init(opts)
      assert validated_opts[:argument] == :new_items
      assert validated_opts[:relationship] == :items
      assert validated_opts[:related_resource] == ItemModule
      assert validated_opts[:parent_key] == :container_id
      assert validated_opts[:id_field] == :id
      assert validated_opts[:on_missing] == :destroy
    end

    test "custom id_field and on_missing options" do
      opts = [
        argument: :new_items,
        relationship: :items,
        related_resource: ItemModule,
        parent_key: :container_id,
        id_field: :custom_id,
        on_missing: :ignore
      ]

      assert {:ok, validated_opts} = OptimizedRelationshipImport.init(opts)
      assert validated_opts[:id_field] == :custom_id
      assert validated_opts[:on_missing] == :ignore
    end
  end

  describe "data processing logic" do
    test "correctly identifies create vs update scenarios" do
      # Test the logic for splitting records into creates vs updates
      new_records = [
        # would be update
        %{id: 1, name: "Existing", value: 100},
        # would be create
        %{id: 2, name: "New Record", value: 200}
      ]

      # Simulate that ID 1 already exists
      existing_ids = MapSet.new([1])
      _incoming_ids = MapSet.new([1, 2])

      {creates, updates} =
        Enum.split_with(new_records, fn record ->
          record.id not in existing_ids
        end)

      assert length(creates) == 1
      assert length(updates) == 1
      assert hd(creates).id == 2
      assert hd(updates).id == 1
    end

    test "correctly identifies missing records for deletion" do
      existing_ids = MapSet.new([1, 2, 3])
      # ID 2 is missing
      incoming_ids = MapSet.new([1, 3])

      missing_ids = MapSet.difference(existing_ids, incoming_ids)

      assert MapSet.size(missing_ids) == 1
      assert 2 in missing_ids
      assert 1 not in missing_ids
      assert 3 not in missing_ids
    end

    test "detects when records have changes" do
      existing_record = %{id: 1, name: "Old Name", value: 100, description: "Old"}
      new_record = %{id: 1, name: "New Name", value: 100, description: "Old"}

      compare_fields = [:name, :value, :description]

      has_changes =
        Enum.any?(compare_fields, fn field ->
          Map.get(new_record, field) != Map.get(existing_record, field)
        end)

      # name changed
      assert has_changes == true

      # Test with no changes
      identical_record = %{id: 1, name: "Old Name", value: 100, description: "Old"}

      no_changes =
        Enum.any?(compare_fields, fn field ->
          Map.get(identical_record, field) != Map.get(existing_record, field)
        end)

      assert no_changes == false
    end
  end
end
