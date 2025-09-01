defmodule Resdayn.Codex.Importable do
  @moduledoc """
  An extension to add to all resources that can be imported from data files.

  This extension will:
  * Define `import_create` and `import_update` actions that accept all public attributes
  """
  use Spark.Dsl.Extension,
    transformers: [__MODULE__.AddImportAction]

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
      |> Ash.Resource.Builder.add_attribute(:flags, {:array, Resdayn.Codex.Flags},
        allow_nil?: false,
        default: []
      )
      |> Ash.Resource.Builder.add_new_action(:create, :import_create,
        accept: attribute_names ++ belongs_to_ids ++ [:flags]
      )
      |> Ash.Resource.Builder.add_new_action(:update, :import_update,
        accept: attribute_names ++ belongs_to_ids ++ [:flags],
        require_atomic?: false
      )
    end

    def before?(_), do: true
  end
end
