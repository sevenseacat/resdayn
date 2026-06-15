defmodule Resdayn.Catalog.Export.EspBuilderTest do
  use Resdayn.IntegrationCase

  require Ash.Query

  alias Resdayn.Catalog.Export.{EspBuilder, Override}

  describe "run/2" do
    test "destroys overrides after successful export" do
      Override
      |> Ash.Changeset.for_create(:create, %{
        record_id: "hammer_repair",
        resource_type: :tool
      })
      |> Ash.create!()

      Override
      |> Ash.Changeset.for_create(:create, %{
        record_id: "pick_master",
        resource_type: :tool
      })
      |> Ash.create!()

      query =
        Override
        |> Ash.Query.filter(record_id in ["hammer_repair", "pick_master"])

      {:ok, binary} = EspBuilder.run(query)
      assert byte_size(binary) > 0

      remaining = Ash.read!(query)
      assert remaining == []
    end

    test "does not destroy overrides outside the query" do
      Override
      |> Ash.Changeset.for_create(:create, %{
        record_id: "hammer_repair",
        resource_type: :tool
      })
      |> Ash.create!()

      keeper =
        Override
        |> Ash.Changeset.for_create(:create, %{
          record_id: "pick_apprentice",
          resource_type: :tool
        })
        |> Ash.create!()

      query =
        Override
        |> Ash.Query.filter(record_id == "hammer_repair")

      {:ok, _binary} = EspBuilder.run(query)

      assert Ash.get!(Override, keeper.id)
    end
  end
end
