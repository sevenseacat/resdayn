defmodule Resdayn.Codex.Importable do
  @moduledoc """
  An extension to add to all resources that can be imported from data files.

  This extension adds:
  * `flags` - Array of record flags from the data file
  * `source_file_ids` - List of data files that contributed to this record
  """
  use Spark.Dsl.Extension,
    transformers: [__MODULE__.AddImportAttributes]

  defmodule AddImportAttributes do
    use Spark.Dsl.Transformer

    def transform(dsl_state) do
      dsl_state
      |> Ash.Resource.Builder.add_attribute(:flags, {:array, Resdayn.Codex.Flags},
        allow_nil?: false,
        default: []
      )
      |> Ash.Resource.Builder.add_attribute(:source_file_ids, {:array, :string},
        allow_nil?: false,
        default: [],
        description: "List of data files that contributed to this record"
      )
    end

    def before?(_), do: true
  end
end
