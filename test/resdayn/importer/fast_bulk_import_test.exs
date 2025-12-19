defmodule Resdayn.Importer.FastBulkImportTest do
  use Resdayn.DataCase, async: true

  alias Resdayn.Importer.FastBulkImport
  alias Resdayn.Codex.Mechanics.GameSetting

  describe "prepare_record/3" do
    setup do
      attributes = Ash.Resource.Info.attributes(GameSetting)
      %{attributes: attributes}
    end

    test "casts and dumps string id", %{attributes: attributes} do
      record = %{id: "sTestSetting", value: "hello"}
      result = FastBulkImport.prepare_record(record, attributes, "Test.esm")

      assert result.id == "sTestSetting"
    end

    test "casts and dumps string value in union type", %{attributes: attributes} do
      record = %{id: "sTestSetting", value: "hello world"}
      result = FastBulkImport.prepare_record(record, attributes, "Test.esm")

      # Union types dump to a tagged format with string keys and atom type value
      assert result.value == %{"type" => :string, "value" => "hello world"}
    end

    test "casts and dumps integer value in union type", %{attributes: attributes} do
      record = %{id: "iTestSetting", value: 42}
      result = FastBulkImport.prepare_record(record, attributes, "Test.esm")

      assert result.value == %{"type" => :integer, "value" => 42}
    end

    test "casts and dumps float value in union type", %{attributes: attributes} do
      record = %{id: "fTestSetting", value: 3.14}
      result = FastBulkImport.prepare_record(record, attributes, "Test.esm")

      assert result.value == %{"type" => :float, "value" => 3.14}
    end

    test "sets source_file_ids from parameter", %{attributes: attributes} do
      record = %{id: "sTest", value: "test"}
      result = FastBulkImport.prepare_record(record, attributes, "Morrowind.esm")

      assert result.source_file_ids == ["Morrowind.esm"]
    end

    test "sets default empty flags array", %{attributes: attributes} do
      record = %{id: "sTest", value: "test"}
      result = FastBulkImport.prepare_record(record, attributes, "Test.esm")

      assert result.flags == []
    end

    test "casts flags array of atoms", %{attributes: attributes} do
      # Use valid flag values: :blocked and :persistent
      record = %{id: "sTest", value: "test", flags: [:blocked, :persistent]}
      result = FastBulkImport.prepare_record(record, attributes, "Test.esm")

      # Flags should be dumped as strings for PostgreSQL array
      assert result.flags == ["blocked", "persistent"]
    end

    test "handles nil value in union type", %{attributes: attributes} do
      record = %{id: "sTest", value: nil}
      result = FastBulkImport.prepare_record(record, attributes, "Test.esm")

      assert result.value == nil
    end
  end

  describe "import/3" do
    test "imports new records" do
      records = [
        %{id: "sTestImport1", value: "value1", flags: []},
        %{id: "sTestImport2", value: 123, flags: []},
        %{id: "sTestImport3", value: 1.5, flags: []}
      ]

      {:ok, stats} = FastBulkImport.import(records, GameSetting, source_file_id: "Test.esm")

      assert stats.total == 3

      # Verify records were inserted
      setting1 = Ash.get!(GameSetting, "sTestImport1")
      assert setting1.value == %Ash.Union{type: :string, value: "value1"}
      assert setting1.source_file_ids == ["Test.esm"]

      setting2 = Ash.get!(GameSetting, "sTestImport2")
      assert setting2.value == %Ash.Union{type: :integer, value: 123}

      setting3 = Ash.get!(GameSetting, "sTestImport3")
      assert setting3.value == %Ash.Union{type: :float, value: 1.5}
    end

    test "upserts existing records and merges source file ids" do
      # First import
      records1 = [%{id: "sTestUpsert", value: "original", flags: []}]
      {:ok, _} = FastBulkImport.import(records1, GameSetting, source_file_id: "Base.esm")

      # Verify initial state
      setting = Ash.get!(GameSetting, "sTestUpsert")
      assert setting.value == %Ash.Union{type: :string, value: "original"}
      assert setting.source_file_ids == ["Base.esm"]

      # Second import with different source file and updated value
      records2 = [%{id: "sTestUpsert", value: "updated", flags: []}]
      {:ok, stats} = FastBulkImport.import(records2, GameSetting, source_file_id: "Expansion.esm")

      assert stats.total == 1

      # Verify upsert merged source files and updated value
      updated = Ash.get!(GameSetting, "sTestUpsert")
      assert updated.value == %Ash.Union{type: :string, value: "updated"}
      assert updated.source_file_ids == ["Base.esm", "Expansion.esm"]
    end

    test "does not duplicate source file id on re-import" do
      # First import
      records = [%{id: "sTestDupe", value: "test", flags: []}]
      {:ok, _} = FastBulkImport.import(records, GameSetting, source_file_id: "Same.esm")

      # Re-import with same source file
      {:ok, _} = FastBulkImport.import(records, GameSetting, source_file_id: "Same.esm")

      # Verify source file not duplicated
      setting = Ash.get!(GameSetting, "sTestDupe")
      assert setting.source_file_ids == ["Same.esm"]
    end

    test "handles empty records list" do
      {:ok, stats} = FastBulkImport.import([], GameSetting, source_file_id: "Test.esm")

      assert stats.inserted == 0
      assert stats.updated == 0
    end

    test "handles large batches" do
      # Create 1500 records to test chunking (chunk size is 1000)
      records =
        for i <- 1..1500 do
          %{id: "sTestBatch#{i}", value: "value#{i}", flags: []}
        end

      {:ok, stats} = FastBulkImport.import(records, GameSetting, source_file_id: "Test.esm")

      assert stats.total == 1500

      # Spot check some records
      assert Ash.get!(GameSetting, "sTestBatch1").value == %Ash.Union{
               type: :string,
               value: "value1"
             }

      assert Ash.get!(GameSetting, "sTestBatch1500").value == %Ash.Union{
               type: :string,
               value: "value1500"
             }
    end
  end

  describe "type casting" do
    test "handles atom flags correctly" do
      attributes = Ash.Resource.Info.attributes(GameSetting)
      # Use valid flag values: :blocked and :persistent
      record = %{id: "sTest", value: "test", flags: [:blocked, :persistent]}
      result = FastBulkImport.prepare_record(record, attributes, "Test.esm")

      # Enum array types should be dumped as string arrays
      assert is_list(result.flags)
      assert "blocked" in result.flags
      assert "persistent" in result.flags
    end

    test "union types are correctly cast and dumped" do
      attributes = Ash.Resource.Info.attributes(GameSetting)

      record = %{id: "test_string", value: "hello", flags: []}
      prepared = FastBulkImport.prepare_record(record, attributes, "Test.esm")
      assert prepared.value == %{"type" => :string, "value" => "hello"}

      record = %{id: "test_int", value: 42, flags: []}
      prepared = FastBulkImport.prepare_record(record, attributes, "Test.esm")
      assert prepared.value == %{"type" => :integer, "value" => 42}

      record = %{id: "test_float", value: 3.14, flags: []}
      prepared = FastBulkImport.prepare_record(record, attributes, "Test.esm")
      assert prepared.value == %{"type" => :float, "value" => 3.14}
    end

    test "enum arrays (flags) are correctly cast and dumped" do
      attributes = Ash.Resource.Info.attributes(GameSetting)

      record = %{id: "test_flags", value: "test", flags: [:blocked, :persistent]}
      prepared = FastBulkImport.prepare_record(record, attributes, "Test.esm")
      assert prepared.flags == ["blocked", "persistent"]
    end

    test "source_file_ids is set correctly" do
      attributes = Ash.Resource.Info.attributes(GameSetting)

      record = %{id: "test_source", value: "test", flags: []}
      prepared = FastBulkImport.prepare_record(record, attributes, "MyMod.esm")
      assert prepared.source_file_ids == ["MyMod.esm"]
    end
  end
end
