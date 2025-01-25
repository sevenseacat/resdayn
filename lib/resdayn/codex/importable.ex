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
      dsl_state
      |> Ash.Resource.Builder.add_action(:create, :import,
        accept: [:*],
        upsert?: true,
        upsert_fields: :replace_all
      )
    end

    def before?(_), do: true
  end
end
