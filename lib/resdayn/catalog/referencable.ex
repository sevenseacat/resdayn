defmodule Resdayn.Catalog.Referencable do
  @moduledoc """
  Marks a resource as a *referencable object* — something a cell reference or an
  inventory item can point at (a weapon, book, NPC, door, …).

  > #### Not fully implemented {: .warning}
  >
  > Today this extension functions **only as a marker**. The importer checks
  > whether a resource carries it (`Referencable in extensions`) to decide
  > whether to populate the `referencable_objects` table for that resource — and
  > then does the insert itself, in raw SQL
  > (`Resdayn.Importer.RecordUpserter.upsert_referencable_objects/2`).
  >
  > Everything the transformer *adds* is currently dormant and unexercised:
  >
  >   * `CreateReferencableObject` / `DeleteReferencableObject` are registered on
  >     the `:create` / `:destroy` actions, but nothing creates or destroys a
  >     referencable resource through Ash — the importer is raw SQL, and the
  >     resources' default `:create` actions don't even accept inputs yet. These
  >     changes have never run.
  >   * The `cell_references_count` / `inventory_items_count` aggregates and the
  >     `:referencable_object` relationship are not referenced anywhere.
  >
  > This is vestigial from an earlier design that imported all data through Ash
  > changesets (which *would* have fired the create change per record). That was
  > far too slow and was replaced by the raw-SQL importer, which bypasses Ash
  > actions and orphaned this machinery.
  >
  > To revive it, a create/delete UI would need to give these resources
  > functional `:create` / `:destroy` actions (with real `accept` lists); the
  > changes would then activate and should be covered by a test.

  > #### Removing this extension from a resource {: .tip}
  >
  > `mix ash.codegen` will emit a `create index(:<table>, [:id])` alongside the
  > dropped foreign key, to replace the index the FK provided. Delete it. `id` is
  > already the primary key, so the index only duplicates `<table>_pkey`.
  >
  > Leaving it in is how 17 of these accumulated between May 2025 and August 2026
  > (see `20260808121643_drop_redundant_id_indexes`). They were invisible to
  > codegen the whole time, because AshPostgres diffs snapshot against snapshot
  > and never against the database — so DDL that no snapshot records simply does
  > not exist as far as future migrations are concerned.
  """
  use Spark.Dsl.Extension, transformers: [__MODULE__.AddReference]

  defmodule AddReference do
    use Spark.Dsl.Transformer

    def before?(Ash.Resource.Transformers.SetRelationshipSource), do: true
    def before?(_), do: false

    def transform(dsl_state) do
      object_type =
        dsl_state.persist.module
        |> Resdayn.Catalog.World.ReferencableObject.Type.resource_to_type()

      dsl_state
      |> Ash.Resource.Builder.add_relationship(
        :belongs_to,
        :referencable_object,
        Resdayn.Catalog.World.ReferencableObject,
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
      # Dormant — see the "Not fully implemented" note in the module doc. These
      # changes are wired up but never fire (the importer bypasses Ash actions).
      |> Ash.Resource.Builder.add_change(
        {Resdayn.Catalog.Changes.CreateReferencableObject, object_type: object_type},
        on: [:create]
      )
      |> Ash.Resource.Builder.add_change(
        {Resdayn.Catalog.Changes.DeleteReferencableObject, []},
        on: [:destroy]
      )
    end
  end
end
