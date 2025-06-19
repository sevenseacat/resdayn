defmodule Resdayn.Importer.Record.DialogueTopic do
  use Resdayn.Importer.Record

  def process(records, opts) do
    records
    |> chunked_dialogues()
    |> Enum.map(fn {record, _} ->
      record.data
      |> with_flags(:flags, record.flags)
    end)
    |> separate_for_import(Resdayn.Codex.Dialogue.Topic, opts)
  end
end
