defmodule Mix.Tasks.Resdayn.ImportCodex do
  use Mix.Task

  require Logger

  # All of the files we care about parsing.
  @all_files [
    "Morrowind.esm",
    "Tribunal.esm",
    "Bloodmoon.esm",
    # "master_index.esp",
    # "Tamriel_Data.esm",
    # "TR_Mainland.esm",
    # "TR_Factions.esp"
  ]

  @requirements ["app.start --preload-modules"]

  def run([filename]) do
    Resdayn.Importer.Runner.run(filename)
  end

  def run(_argv) do
    Logger.configure(level: :info)

    Enum.map(@all_files, &Resdayn.Importer.Runner.run/1)
    collate_named_quests()
    run_quest_analyzer()
    rebuild_search_index()
  end

  defp rebuild_search_index do
    Logger.notice("Rebuilding search index...")

    {time, count} = :timer.tc(&Resdayn.Importer.SearchIndex.rebuild/0, :millisecond)

    Logger.notice(
      "Search index rebuilt with #{count} entries in #{Float.round(time / 1000, 2)} seconds."
    )
  end

  defp collate_named_quests do
    Logger.notice("Collating named quests...")

    {time, count} = :timer.tc(&Resdayn.Importer.Record.Quest.collate/0, :millisecond)

    Logger.notice(
      "Named quests collated with #{count} entries in #{Float.round(time / 1000, 2)} seconds."
    )
  end

  defp run_quest_analyzer do
    Logger.notice("Running quest analyzer...")

    {time, counts} = :timer.tc(&Resdayn.QuestAnalyzer.run/0, :millisecond)

    Logger.notice(
      "Quest analyzer completed in #{Float.round(time / 1000, 2)} seconds: #{inspect(counts)}"
    )
  end
end
