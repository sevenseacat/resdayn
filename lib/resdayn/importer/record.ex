defmodule Resdayn.Importer.Record do
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

  @doc """
  Groups dialogue records into `{topic, responses}` pairs, with the responses in
  the order they appear in the file. That order is meaningful: the game engine
  walks a topic's INFO records front-to-back.
  """
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
    |> Enum.map(fn {topic, responses} -> {topic, Enum.reverse(responses)} end)
  end

  @doc """
  The INFO record that gives a journal quest its name: the first QSTN-flagged
  response in record order, which is the one the game engine settles on. A few
  quests carry more than one because Bethesda left the flag on a real journal
  entry, so "first" matters - see `Resdayn.Importer.Record.JournalEntry`.
  """
  def quest_name_response(responses) do
    Enum.find(responses, & &1.data[:quest_name])
  end

  defmacro __using__(_opts) do
    quote do
      import Resdayn.Importer.Record
    end
  end
end
