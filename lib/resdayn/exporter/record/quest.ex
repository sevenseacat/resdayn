defmodule Resdayn.Exporter.Record.Quest do
  @moduledoc """
  Encodes a `Resdayn.Codex.Dialogue.Quest` resource as a journal DIAL record
  followed by INFO records for each `JournalEntry`.
  """

  import Resdayn.Parser.DataSizes
  import Resdayn.Exporter.Helpers

  alias Resdayn.Exporter.Record.Topic

  def encode(quest) do
    dial = Topic.encode_dial(quest.id, :journal)

    # Auto-generate a naming entry (QSTN) from quest.name at index 0,
    # followed by the actual journal entries
    name_entry = %{id: "#{quest.id}_name", index: 0, content: quest.name}
    journal_entries = ensure_list(quest.journal_entries)
    all_entries = [name_entry | journal_entries]

    infos =
      all_entries
      |> link_entries()
      |> Enum.with_index()
      |> Enum.map(fn {entry, i} -> encode_entry(entry, quest_name: i == 0) end)

    [dial | infos]
  end

  defp ensure_list(entries) when is_list(entries), do: entries
  defp ensure_list(_not_loaded), do: []

  defp link_entries(entries) do
    ids = Enum.map(entries, & &1.id)

    entries
    |> Enum.with_index()
    |> Enum.map(fn {entry, i} ->
      {entry, if(i > 0, do: Enum.at(ids, i - 1)), Enum.at(ids, i + 1)}
    end)
  end

  defp encode_entry({entry, prev_id, next_id}, opts) do
    subrecords =
      [
        {"INAM", null_terminate(entry.id)},
        {"PNAM", null_terminate(prev_id)},
        {"NNAM", null_terminate(next_id)},
        {"DATA",
         <<4::uint8(), 0::size(24), entry.index::uint32(), -1::int8(), -1::int8(), -1::int8(),
           0::uint8()>>},
        {"NAME", null_terminate(encode_string(entry.content))},
        if(opts[:quest_name], do: {"QSTN", <<1>>}),
        if(Map.get(entry, :finishes_quest), do: {"QSTF", <<1>>}),
        if(Map.get(entry, :restarts_quest), do: {"QSTR", <<1>>})
      ]
      |> Enum.reject(&is_nil/1)

    {"INFO", %{}, subrecords}
  end
end
