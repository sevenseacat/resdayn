defmodule Resdayn.Codex.Export.OverrideTest do
  use Resdayn.IntegrationCase

  alias Resdayn.Codex.Export.Override

  describe "create" do
    test "creates an override for a record" do
      override =
        Override
        |> Ash.Changeset.for_create(:create, %{
          record_id: "pick_apprentice_01",
          resource_type: :tool
        })
        |> Ash.create!()

      assert to_string(override.record_id) == "pick_apprentice_01"
      assert override.resource_type == :tool
      assert override.inserted_at
      assert override.updated_at
    end

    test "upserts on the same record, updating only updated_at" do
      attrs = %{record_id: "probe_apprentice_01", resource_type: :tool}

      original =
        Override
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create!()

      upserted =
        Override
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create!()

      assert original.id == upserted.id
      assert original.inserted_at == upserted.inserted_at
      assert DateTime.compare(upserted.updated_at, original.updated_at) == :gt
    end

    test "allows different records with different IDs" do
      Override
      |> Ash.Changeset.for_create(:create, %{
        record_id: "probe_journeyman_01",
        resource_type: :tool
      })
      |> Ash.create!()

      override2 =
        Override
        |> Ash.Changeset.for_create(:create, %{
          record_id: "probe_bent",
          resource_type: :tool
        })
        |> Ash.create!()

      assert to_string(override2.record_id) == "probe_bent"
    end
  end

  describe "exportable extension" do
    test "updating a tool automatically creates an override" do
      tool = Ash.get!(Resdayn.Codex.Items.Tool, "hammer_repair")

      tool
      |> Ash.Changeset.for_update(:update, %{name: "Modified Hammer"})
      |> Ash.update!()

      override =
        Override
        |> Ash.get!(record_id: "hammer_repair", resource_type: :tool)

      assert to_string(override.record_id) == "hammer_repair"
      assert override.resource_type == :tool
    end

    test "updating a tool twice upserts the same override" do
      tool = Ash.get!(Resdayn.Codex.Items.Tool, "pick_master")

      tool
      |> Ash.Changeset.for_update(:update, %{name: "Modified Pick"})
      |> Ash.update!()

      first_override =
        Override
        |> Ash.get!(record_id: "pick_master", resource_type: :tool)

      tool
      |> Ash.Changeset.for_update(:update, %{name: "Modified Pick Again"})
      |> Ash.update!()

      second_override =
        Override
        |> Ash.get!(record_id: "pick_master", resource_type: :tool)

      assert first_override.id == second_override.id
      assert DateTime.compare(second_override.updated_at, first_override.updated_at) == :gt
    end
  end

  describe "record calculation" do
    test "loads the referenced record for an override" do
      override =
        Override
        |> Ash.Changeset.for_create(:create, %{
          record_id: "pick_grandmaster",
          resource_type: :tool
        })
        |> Ash.create!()

      loaded = Ash.load!(override, [:record])
      assert loaded.record.__struct__ == Resdayn.Codex.Items.Tool
      assert to_string(loaded.record.id) == "pick_grandmaster"
    end

    test "loads records for multiple overrides of different types" do
      override1 =
        Override
        |> Ash.Changeset.for_create(:create, %{
          record_id: "pick_secretmaster",
          resource_type: :tool
        })
        |> Ash.create!()

      override2 =
        Override
        |> Ash.Changeset.for_create(:create, %{
          record_id: "probe_master",
          resource_type: :tool
        })
        |> Ash.create!()

      [loaded1, loaded2] = Ash.load!([override1, override2], [:record])

      assert loaded1.record.__struct__ == Resdayn.Codex.Items.Tool
      assert loaded2.record.__struct__ == Resdayn.Codex.Items.Tool
      assert to_string(loaded1.record.id) == "pick_secretmaster"
      assert to_string(loaded2.record.id) == "probe_master"
    end
  end
end
