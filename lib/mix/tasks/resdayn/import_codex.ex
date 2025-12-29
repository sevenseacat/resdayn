defmodule Mix.Tasks.Resdayn.ImportCodex do
  use Mix.Task

  require Logger

  # All of the files we care about parsing.
  @all_files [
    "Morrowind.esm",
    "Tribunal.esm",
    "Bloodmoon.esm",
    "master_index.esp",
    "Tamriel_Data.esm",
    "TR_Mainland.esm",
    "TR_Factions.esp",
    "Sky_Main.esm",
    "Cyr_Main.esm"
  ]

  @requirements ["app.start"]

  def run([filename]) do
    Resdayn.Importer.Runner.run(filename)
  end

  def run(_argv) do
    Enum.map(@all_files, &Resdayn.Importer.Runner.run/1)
    rebuild_search_index()
  end

  defp rebuild_search_index do
    Logger.info("Rebuilding search index...")

    {time, count} =
      :timer.tc(
        fn ->
          Resdayn.Importer.SearchIndex.rebuild()
        end,
        :millisecond
      )

    Logger.info(
      "Search index rebuilt with #{count} entries in #{Float.round(time / 1000, 2)} seconds."
    )
  end
end
