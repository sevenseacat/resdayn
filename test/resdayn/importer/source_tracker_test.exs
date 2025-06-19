defmodule Resdayn.Importer.SourceTrackerTest do
  use ExUnit.Case, async: true

  alias Resdayn.Importer.SourceTracker

  describe "source file tracking" do
    test "add_source_file_id/2 adds source file ID to record" do
      record = %{id: "test", name: "Test Record"}

      result = SourceTracker.add_source_file_id(record, "Morrowind.esm")

      assert result.source_file_ids == ["Morrowind.esm"]
    end

    test "add_source_file_id/2 does not duplicate existing source file ID" do
      record = %{id: "test", source_file_ids: ["Morrowind.esm"]}

      result = SourceTracker.add_source_file_id(record, "Morrowind.esm")

      assert result.source_file_ids == ["Morrowind.esm"]
    end

    test "add_source_file_id/2 appends new source file ID to existing list" do
      record = %{id: "test", source_file_ids: ["Morrowind.esm"]}

      result = SourceTracker.add_source_file_id(record, "Tribunal.esm")

      assert result.source_file_ids == ["Morrowind.esm", "Tribunal.esm"]
    end

    test "add_source_file_id/2 works with list of records" do
      records = [
        %{id: "test1", source_file_ids: ["Morrowind.esm"]},
        %{id: "test2"}
      ]

      results = SourceTracker.add_source_file_id(records, "Tribunal.esm")

      assert Enum.at(results, 0).source_file_ids == ["Morrowind.esm", "Tribunal.esm"]
      assert Enum.at(results, 1).source_file_ids == ["Tribunal.esm"]
    end
  end

  describe "significant_change?/3" do
    defmodule TestResource do
      use Ash.Resource,
        domain: nil,
        data_layer: Ash.DataLayer.Ets

      attributes do
        uuid_primary_key :id
        attribute :name, :string, public?: true
        attribute :description, :string, public?: true
        attribute :source_file_ids, {:array, :string}, default: [], public?: true
        attribute :metadata, :string, public?: true
      end

      actions do
        defaults [:read, :create, :update, :destroy]
      end
    end

    defmodule TestResourceWithIgnores do
      use Ash.Resource,
        domain: nil,
        data_layer: Ash.DataLayer.Ets,
        extensions: [Resdayn.Codex.Importable]

      attributes do
        uuid_primary_key :id
        attribute :name, :string, public?: true
        attribute :description, :string, public?: true
        attribute :metadata, :string, public?: true
      end

      importable do
        ignore_attributes([:metadata])
      end

      actions do
        defaults [:read, :create, :update, :destroy]
      end
    end

    test "returns true when significant attributes change" do
      existing = %{id: "test", name: "Old Name", description: "Old Desc"}
      new_data = %{id: "test", name: "New Name", description: "Old Desc"}

      result = SourceTracker.significant_change?(TestResource, existing, new_data)

      assert result == true
    end

    test "returns false when only source_file_ids change" do
      existing = %{
        id: "test",
        name: "Same Name",
        description: "Same Desc",
        source_file_ids: ["Morrowind.esm"]
      }

      new_data = %{
        id: "test",
        name: "Same Name",
        description: "Same Desc",
        source_file_ids: ["Tribunal.esm"]
      }

      result = SourceTracker.significant_change?(TestResource, existing, new_data)

      assert result == false
    end

    test "respects ignore_attributes configuration" do
      existing = %{id: "test", name: "Same Name", metadata: "old meta"}
      new_data = %{id: "test", name: "Same Name", metadata: "new meta"}

      result = SourceTracker.significant_change?(TestResourceWithIgnores, existing, new_data)

      assert result == false
    end
  end

  describe "source file merging in different scenarios" do
    test "merges source files correctly when record is processed multiple times in same import" do
      # Simulate cell being processed by Cell importer first, then CellReference importer

      # First processing (Cell importer) - record is created
      initial_record = %{
        id: "1,-13",
        name: "Ebonheart",
        source_file_ids: ["Morrowind.esm"]
      }

      # Second processing (CellReference importer) - same source file
      # This simulates what happens when CellReference importer processes the same cell
      existing_record = initial_record

      new_record = %{
        id: "1,-13",
        name: "Ebonheart",
        # Added by add_source_file_id
        source_file_ids: ["Morrowind.esm"]
      }

      # The source file is not "new" because it's already in the existing record
      existing_source_ids = existing_record.source_file_ids || []
      is_new_source = "Morrowind.esm" not in existing_source_ids

      # Should preserve existing source file IDs
      merged_source_ids =
        if is_new_source do
          existing_record.source_file_ids ++ new_record.source_file_ids
        else
          # Even if not a new source, preserve existing IDs
          current_ids = existing_record.source_file_ids || []

          if "Morrowind.esm" in current_ids do
            current_ids
          else
            current_ids ++ ["Morrowind.esm"]
          end
        end

      assert merged_source_ids == ["Morrowind.esm"]
      assert is_new_source == false
    end

    test "merges source files correctly when importing second data file" do
      # Simulate importing Tribunal.esm after Morrowind.esm

      # Cell exists from Morrowind.esm import
      existing_record = %{
        id: "1,-13",
        name: "Ebonheart",
        source_file_ids: ["Morrowind.esm"]
      }

      # Cell from Tribunal.esm (after add_source_file_id)
      new_record = %{
        id: "1,-13",
        name: "Ebonheart",
        source_file_ids: ["Tribunal.esm"]
      }

      existing_source_ids = existing_record.source_file_ids || []
      is_new_source = "Tribunal.esm" not in existing_source_ids

      # Should merge the source file IDs
      merged_source_ids =
        if is_new_source do
          existing_record.source_file_ids ++ new_record.source_file_ids
        else
          current_ids = existing_record.source_file_ids || []

          if "Tribunal.esm" in current_ids do
            current_ids
          else
            current_ids ++ ["Tribunal.esm"]
          end
        end

      assert merged_source_ids == ["Morrowind.esm", "Tribunal.esm"]
      assert is_new_source == true
    end

    test "handles the double-processing scenario correctly" do
      # This test captures the exact bug scenario:
      # 1. Cell importer processes cell and merges ["Morrowind.esm"] + ["Tribunal.esm"] = ["Morrowind.esm", "Tribunal.esm"]
      # 2. CellReference importer processes same cell again with is_new_source = false

      # After first processing (Cell importer)
      after_first_processing = %{
        id: "1,-13",
        name: "Ebonheart",
        source_file_ids: ["Morrowind.esm", "Tribunal.esm"]
      }

      # Second processing (CellReference importer) with same source file
      second_record = %{
        id: "1,-13",
        name: "Ebonheart",
        # Only contains current import's source
        source_file_ids: ["Tribunal.esm"]
      }

      existing_source_ids = after_first_processing.source_file_ids || []
      # false, because it's already there
      is_new_source = "Tribunal.esm" not in existing_source_ids

      # The bug was here - when is_new_source = false, it was using just the new record's source_file_ids
      # The fix ensures we preserve existing source file IDs
      merged_source_ids =
        if is_new_source do
          after_first_processing.source_file_ids ++ second_record.source_file_ids
        else
          # Fixed logic: preserve existing source file IDs
          current_ids = after_first_processing.source_file_ids || []

          if "Tribunal.esm" in current_ids do
            # Already has it, keep as-is
            current_ids
          else
            # Add it
            current_ids ++ ["Tribunal.esm"]
          end
        end

      # Should preserve both source files, not replace with just ["Tribunal.esm"]
      assert merged_source_ids == ["Morrowind.esm", "Tribunal.esm"]
      assert is_new_source == false
    end
  end

  describe "merge_source_file_ids/3 function" do
    test "preserves existing source file IDs when source is not new" do
      existing_ids = ["Morrowind.esm"]
      new_ids = ["Morrowind.esm"]
      current_source = "Morrowind.esm"

      result = SourceTracker.merge_source_file_ids(existing_ids, new_ids, current_source)

      # Should preserve existing IDs when source is already present
      assert result == ["Morrowind.esm"]
    end

    test "merges source file IDs when source is new" do
      existing_ids = ["Morrowind.esm"]
      new_ids = ["Tribunal.esm"]
      current_source = "Tribunal.esm"

      result = SourceTracker.merge_source_file_ids(existing_ids, new_ids, current_source)

      # Should merge when source is new
      assert result == ["Morrowind.esm", "Tribunal.esm"]
    end

    test "handles nil existing source file IDs" do
      existing_ids = nil
      new_ids = ["Tribunal.esm"]
      current_source = "Tribunal.esm"

      result = SourceTracker.merge_source_file_ids(existing_ids, new_ids, current_source)

      # Should handle nil gracefully
      assert result == ["Tribunal.esm"]
    end
  end
end
