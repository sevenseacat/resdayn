defmodule Resdayn.Importer.Record.Script do
  use Resdayn.Importer.Record
  alias Resdayn.Parser.Record

  def process(records, opts) do
    start_scripts = records |> of_type(Record.StartScript) |> Enum.map(& &1.data.script_id)

    records
    |> of_type(Record.Script)
    |> Enum.map(fn record ->
      record.data
      |> Map.take([:id, :text, :local_variables])
      |> Map.put(:start_script, record.data.id in start_scripts)
      |> with_flags(:flags, record.flags)
    end)
    |> separate_for_import(Resdayn.Codex.Mechanics.Script, opts)
  end
end
