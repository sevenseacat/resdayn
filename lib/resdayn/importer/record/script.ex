defmodule Resdayn.Importer.Record.Script do
  use Resdayn.Importer.Record
  alias Resdayn.Parser.Record

  def process(records, _opts) do
    start_scripts = records |> of_type(Record.StartScript) |> Enum.map(& &1.data.script_id)

    processed_records =
      records
      |> of_type(Record.Script)
      |> Enum.map(fn record ->
        record.data
        |> Map.take([:id, :text, :local_variables])
        |> Map.put(:start_script, record.data.id in start_scripts)
        |> with_flags(:flags, record.flags)
      end)

    %{
      type: :fast_bulk,
      resource: Resdayn.Codex.Mechanics.Script,
      records: processed_records,
      conflict_keys: [:id]
    }
  end
end
