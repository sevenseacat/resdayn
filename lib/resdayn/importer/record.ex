defmodule Resdayn.Importer.Record do
  require Ash.Query

  alias Resdayn.Importer.SourceTracker

  def of_type(records, types) when is_list(types) do
    Enum.filter(records, &(&1.type in types))
  end

  def of_type(records, type) when is_atom(type) do
    Enum.filter(records, &(&1.type == type))
  end

  @doc """
  Only take a subset of the available record flags - the rest appear to be vestigial
  """
  def with_flags(data, key, flags) do
    trues =
      flags
      |> Map.keys()
      |> Enum.filter(fn key -> flags[key] end)

    Map.put(data, key, trues)
  end

  def find_existing(resource, records) do
    ids = Enum.map(records, & &1.id)

    resource
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(id in ^ids)
    |> Ash.read!()
    |> Map.new(&{&1.id, &1})
  end

  def separate_for_import(records, resource, opts \\ []) do
    source_file_id = Keyword.get(opts, :source_file_id)

    # If source tracking is enabled and resource supports it, use SourceTracker
    if source_file_id && has_importable_extension?(resource) do
      SourceTracker.process_with_tracking(records, resource, source_file_id, opts)
    else
      # Legacy path for resources without source tracking
      existing = find_existing(resource, records)
      update_action = Keyword.get(opts, :action, :import_update)

      Enum.reduce(records, %{resource: resource, create: [], update: []}, fn record, acc ->
        if match = Map.get(existing, record.id) do
          changeset = Ash.Changeset.for_update(match, update_action, Map.drop(record, [:id]))
          Map.update!(acc, :update, &[changeset | &1])
        else
          Map.update!(acc, :create, &[record | &1])
        end
      end)
    end
  end

  defp has_importable_extension?(resource) do
    extensions = Spark.extensions(resource)
    Resdayn.Codex.Importable in extensions
  end

  def process_inventory_items(records, parser_type, codex_type, opts \\ []) do
    records
    |> of_type(parser_type)
    |> Enum.reject(&(&1.data.id == "player"))
    |> Enum.map(fn record ->
      inventory =
        Enum.map(record.data[:inventory] || [], fn object ->
          %{
            object_ref_id: object.id,
            count: object.count,
            restocking?: object.restocking
          }
        end)

      record.data
      |> Map.take([:id])
      |> Map.put(:inventory, inventory)
    end)
    |> separate_for_import(codex_type, Keyword.put(opts, :action, :import_relationships))
  end

  def chunked_dialogues(records, type \\ nil) do
    records
    |> Enum.drop_while(fn record -> record.type != Resdayn.Parser.Record.DialogueTopic end)
    |> Enum.chunk_while(
      {nil, []},
      fn
        %{type: Resdayn.Parser.Record.DialogueTopic} = record, acc ->
          {:cont, acc, {record, []}}

        %{type: Resdayn.Parser.Record.DialogueResponse} = record, {topic, responses} ->
          {:cont, {topic, [record | responses]}}
      end,
      fn acc -> {:cont, acc, []} end
    )
    |> tl()
    |> Enum.filter(fn {topic, _} ->
      topic.data.type == :journal == (type == :journal)
    end)
  end

  defmacro __using__(_opts) do
    quote do
      import Resdayn.Importer.Record
    end
  end
end
