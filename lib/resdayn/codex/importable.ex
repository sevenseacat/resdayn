defmodule Resdayn.Codex.Importable do
  @moduledoc """
  An extension to add to all resources that can be imported from data files.

  This extension will:
  * Define `import_create` and `import_update` actions that accept all public attributes
  * Add source file tracking attributes
  * Support configuration of ignore_attributes for change detection
  """

  @importable %Spark.Dsl.Section{
    name: :importable,
    describe: """
    Configuration for importable resources.
    """,
    examples: [
      """
      importable do
        ignore_attributes [:next_dialogue_id, :previous_dialogue_id]
      end
      """
    ],
    schema: [
      ignore_attributes: [
        type: {:list, :atom},
        default: [],
        doc:
          "List of attributes to ignore when determining if a record has changed during import."
      ]
    ]
  }

  use Spark.Dsl.Extension,
    sections: [@importable],
    transformers: [__MODULE__.AddImportAction]

  @doc """
  Get the list of attributes to ignore for change detection during import.
  """
  def ignore_attributes(resource) do
    Spark.Dsl.Extension.get_opt(resource, [:importable], :ignore_attributes, [])
  end

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
      |> Ash.Resource.Builder.add_attribute(:source_file_ids, {:array, :string},
        allow_nil?: false,
        default: [],
        public?: true
      )
      |> Ash.Resource.Builder.add_attribute(:flags, {:array, Resdayn.Codex.Flags},
        allow_nil?: false,
        default: []
      )
      |> Ash.Resource.Builder.add_new_action(:create, :import_create,
        accept: attribute_names ++ belongs_to_ids ++ [:flags, :source_file_ids]
      )
      |> Ash.Resource.Builder.add_new_action(:update, :import_update,
        accept: attribute_names ++ belongs_to_ids ++ [:flags, :source_file_ids],
        require_atomic?: false
      )
    end

    def before?(_), do: true
  end
end
