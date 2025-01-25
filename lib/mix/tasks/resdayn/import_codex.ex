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
    Logger.configure(level: :info)

    Enum.each(@all_files, &run_importer/1)
  end

  def run_importer(filename) do
    records = load_records(filename)

    [
      {Mechanics.DataFile, Record.MainHeader},
      {Mechanics.GameSetting, Record.GameSetting},
      {Mechanics.Script, [Record.Script, Record.StartScript]}
    ]
    |> Enum.each(fn {resource, keys} ->
      import_records(records, resource, keys, filename: filename)
    end)

    IO.puts("")
  end

  defp load_records(filename) do
    Owl.Spinner.start(id: filename)
    Owl.Spinner.update_label(id: filename, label: "#{filename}: Parsing...")

    {time, result} =
      :timer.tc(
        fn -> Resdayn.Parser.read(Path.join(["../data/", filename])) |> Enum.to_list() end,
        :millisecond
      )

    Owl.Spinner.stop(
      id: filename,
      resolution: :ok,
      label: "#{filename}: #{length(result)} records parsed in #{Float.round(time / 1000, 2)}s."
    )

    result
  end

  defp import_records(records, resource, keys, opts) do
    name = String.split(Atom.to_string(resource), ".") |> List.last()

    Owl.Spinner.start(id: resource)
    Owl.Spinner.update_label(id: resource, label: "#{name}: Processing...")

    records = process(records, keys, opts)
    length = length(records)

    Owl.Spinner.update_label(id: resource, label: "#{name}: Inserting #{length} records...")

    result =
      Ash.bulk_create!(records, resource, :import, return_errors?: true, stop_on_error?: true)

    if result.status != :success do
      label = "#{name}: #{result.error_count} errors received."
      Owl.Spinner.stop(id: resource, resolution: :error, label: label)
    else
      label = "#{name}: #{length} records inserted."
      Owl.Spinner.stop(id: resource, resolution: :ok, label: label)
    end
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

  defp process(records, Record.GameSetting, _opts) do
    records
    |> of_type(Record.GameSetting)
    |> Enum.map(fn record ->
      record.data
      |> Map.take([:name, :value])
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
