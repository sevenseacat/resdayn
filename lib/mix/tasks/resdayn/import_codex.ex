defmodule Mix.Tasks.Resdayn.ImportCodex do
  use Mix.Task

  alias Resdayn.Parser.Record
  alias Resdayn.Codex.Mechanics

  # All of the files we care about parsing.
  @all_files [
    "Morrowind.esm",
    "Tribunal.esm",
    "Bloodmoon.esm",
    "master_index.esp",
    "Tamriel_Data.esm",
    "TR_Mainland.esm",
    "TR_Factions.esp"
  ]

  def run(_argv) do
    Application.ensure_all_started(:resdayn)

    @all_files
    |> Enum.each(fn filename ->
      records = Resdayn.Parser.read("../data/#{filename}") |> Enum.to_list()

      [
        {Mechanics.DataFile, Record.MainHeader},
        {Mechanics.Script, [Record.Script, Record.StartScript]}
      ]
      |> Enum.each(fn {resource, keys} ->
        records
        |> process(keys, filename: filename)
        |> Ash.bulk_create!(resource, :import, return_errors?: true, stop_on_error?: true)
      end)
    end)
  end

  defp process(records, [Record.Script, Record.StartScript], _opts) do
    start_scripts = of_type(records, Record.StartScript) |> Enum.map(& &1.data.script_id)

    of_type(records, Record.Script)
    |> Enum.map(fn record ->
      record.data
      |> Map.take([:id, :text, :local_variables])
      |> Map.put(:start_script, record.data.id in start_scripts)
      |> Map.put(:flags, record.flags)
    end)
  end

  defp process(records, Record.MainHeader, opts) do
    with [header] <- of_type(records, Record.MainHeader) do
      [
        header.data.header
        |> Map.take([:version, :company, :description])
        |> Map.merge(%{
          filename: Keyword.fetch!(opts, :filename),
          master: header.data.header.flags.master,
          dependencies: header.data[:dependencies] || []
        })
        |> Map.put(:flags, header.flags)
      ]
    else
      [] -> raise RuntimeError, "No main header found in file"
    end
  end

  defp of_type(records, type) when is_atom(type) do
    Enum.filter(records, &(&1.type == type))
  end
end
