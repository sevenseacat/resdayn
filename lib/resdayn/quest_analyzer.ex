defmodule Resdayn.QuestAnalyzer do
  @moduledoc """
  The secret sauce module that analyzes all of the flat quest data in the database
  and cross-references all of the interesting information.

  `run/1` loads the corpus, runs every extractor, and persists the resulting
  involvement rows. Idempotent — re-running over the same data is a no-op via
  composite unique constraints on each involvement table.

  Pass a list of quest_version ids to scope the run to a subset; useful for
  tests and ad-hoc spelunking from iex.
  """

  require Logger

  alias __MODULE__.{Extractor, LoadedData, Persister}

  def run(quest_ids \\ []) do
    data = time(fn -> LoadedData.load(quest_ids) end, "load")

    npc_rows =
      time(
        fn ->
          Extractor.Characters.dialogue_speakers(data) ++
            Extractor.Characters.script_bearers(data) ++
            Extractor.Characters.effect_targets(data)
        end,
        "extract npc involvements"
      )

    time(fn -> Persister.npc_involvements(npc_rows) end, "persist npc involvements")

    %{npc_involvements: length(npc_rows)}
  end

  defp time(func, label) do
    {time, result} = :timer.tc(func, :millisecond)
    Logger.info("QuestAnalyzer #{label}: #{time}ms")
    result
  end
end
