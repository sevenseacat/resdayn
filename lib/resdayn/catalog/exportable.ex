defmodule Resdayn.Catalog.Exportable do
  @moduledoc """
  An extension for resources that can be exported from the Library.

  This extension will:
  * Add a generic `:update` action accepting all editable attributes
  * Create/upsert an Override record whenever the resource is updated

  Attributes excluded from the update action:
  * Primary key attributes
  * `flags` and `source_file_ids` (added by Importable)
  * Any attribute ending in `_filename` (internal data file references)
  """
  use Spark.Dsl.Extension, transformers: [__MODULE__.AddUpdateAction]

  defmodule AddUpdateAction do
    use Spark.Dsl.Transformer

    @excluded_attributes [:flags, :source_file_ids]

    def transform(dsl_state) do
      resource_type =
        dsl_state.persist.module
        |> Resdayn.Catalog.Export.Override.ResourceType.resource_to_type()

      accepted_attributes =
        dsl_state
        |> Ash.Resource.Info.attributes()
        |> Enum.reject(fn attr ->
          attr.primary_key? ||
            attr.name in @excluded_attributes ||
            String.ends_with?(to_string(attr.name), "_filename")
        end)
        |> Enum.map(& &1.name)

      relationship_attributes =
        dsl_state
        |> Ash.Resource.Info.relationships()
        |> Enum.filter(&(&1.type == :belongs_to))
        |> Enum.map(& &1.source_attribute)
        |> Enum.reject(&(&1 in accepted_attributes))

      dsl_state
      |> Ash.Resource.Builder.add_action(:update, :update,
        accept: accepted_attributes ++ relationship_attributes,
        require_atomic?: false,
        changes: [
          %Ash.Resource.Change{
            change: {Resdayn.Catalog.Changes.CreateOverride, resource_type: resource_type},
            on: [:update],
            where: []
          }
        ]
      )
    end

    def after?(Resdayn.Catalog.Importable.AddImportAttributes), do: true
    def after?(_), do: false
  end
end
