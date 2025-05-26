defmodule Resdayn.Codex.Importable do
  @moduledoc """
  An extension to add to all resources that can be imported from data files.

  This extension will:
  * Define an `import` upsert action that accepts all public attributes

  (and more later but this is enough for now)
  """
  use Spark.Dsl.Extension, transformers: [__MODULE__.AddImportAction]

  defmodule AddImportAction do
    use Spark.Dsl.Transformer

    def transform(dsl_state) do
      attribute_names =
        Ash.Resource.Info.attributes(dsl_state)
        |> Enum.filter(& &1.writable?)
        |> Enum.map(& &1.name)

      belongs_to_ids =
        Enum.filter(Ash.Resource.Info.relationships(dsl_state), &(&1.type == :belongs_to))
        |> Enum.map(& &1.source_attribute)

      dsl_state
      |> Ash.Resource.Builder.add_new_action(:create, :import,
        accept: attribute_names ++ belongs_to_ids ++ [:flags],
        upsert?: true,
        upsert_fields: :replace_all
      )
      |> Ash.Resource.Builder.add_attribute(:flags, {:array, Resdayn.Codex.Flags},
        allow_nil?: false,
        default: []
      )
    end

    def before?(_), do: true
  end
end
