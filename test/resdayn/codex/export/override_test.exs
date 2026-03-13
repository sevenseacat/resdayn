defmodule Resdayn.Codex.Export.OverrideTest do
  use Resdayn.DataCase, async: true

  alias Resdayn.Codex.Export.Override

  describe "create" do
    test "creates an override for a record" do
      override =
        Override
        |> Ash.Changeset.for_create(:create, %{record_id: "hammer_repair", resource_type: :tool})
        |> Ash.create!()

      assert to_string(override.record_id) == "hammer_repair"
      assert override.resource_type == :tool
      assert override.inserted_at
      assert override.updated_at
    end

    test "upserts on the same record, updating only updated_at" do
      attrs = %{record_id: "hammer_apprentice", resource_type: :tool}

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
      assert DateTime.compare(upserted.updated_at, original.updated_at) in [:gt, :eq]
    end

    test "allows different records with different IDs" do
      Override
      |> Ash.Changeset.for_create(:create, %{record_id: "pick_apprentice", resource_type: :tool})
      |> Ash.create!()

      override2 =
        Override
        |> Ash.Changeset.for_create(:create, %{record_id: "pick_journeyman", resource_type: :tool})
        |> Ash.create!()

      assert to_string(override2.record_id) == "pick_journeyman"

      overrides = Ash.read!(Override)
      assert length(overrides) == 2
    end
  end
end
