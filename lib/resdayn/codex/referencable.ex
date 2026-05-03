defmodule Resdayn.Codex.Referencable do
  @moduledoc """
  An extension to add to all resources that can be imported from data files.

  This extension will:
  * Create a `ReferencableObject` whenever a record is created
  """
  use Spark.Dsl.Extension, transformers: [__MODULE__.AddReference]

  defmodule AddReference do
    use Spark.Dsl.Transformer

    def before?(Ash.Resource.Transformers.SetRelationshipSource), do: true
    def before?(_), do: false

    def transform(dsl_state) do
      object_type =
        dsl_state.persist.module
        |> Resdayn.Codex.World.ReferencableObject.Type.resource_to_type()

      dsl_state
      |> Ash.Resource.Builder.add_relationship(
        :belongs_to,
        :referencable_object,
        Resdayn.Codex.World.ReferencableObject,
        source_attribute: :id,
        destination_attribute: :id,
        define_attribute?: false
      )
      |> Ash.Resource.Builder.add_aggregate(
        :cell_references_count,
        :count,
        [:referencable_object, :cell_references]
      )
      |> Ash.Resource.Builder.add_aggregate(
        :inventory_items_count,
        :count,
        [:referencable_object, :inventory_items]
      )
      |> Ash.Resource.Builder.add_change(
        {Resdayn.Codex.Changes.CreateReferencableObject, object_type: object_type},
        on: [:create]
      )
      |> Ash.Resource.Builder.add_change(
        {Resdayn.Codex.Changes.DeleteReferencableObject, []},
        on: [:destroy]
      )
    end
  end
end
