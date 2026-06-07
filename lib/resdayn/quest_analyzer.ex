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

    actor_rows =
      time(
        fn ->
          Extractor.Actors.dialogue_speakers(data) ++
            Extractor.Actors.script_bearers(data) ++
            Extractor.Actors.effect_targets(data)
        end,
        "extract actor involvements"
      )

    time(fn -> Persister.actor_involvements(actor_rows) end, "persist actor involvements")

    item_rows =
      time(
        fn ->
          Extractor.Items.required_items(data) ++
            Extractor.Items.effect_items(data)
        end,
        "extract item involvements"
      )

    time(fn -> Persister.item_involvements(item_rows) end, "persist item involvements")

    transition_rows =
      time(fn -> Extractor.Transitions.discover(data) end, "extract transitions")

    time(fn -> Persister.transitions(transition_rows) end, "persist transitions")

    %{
      actor_involvements: length(actor_rows),
      item_involvements: length(item_rows),
      transitions: length(transition_rows)
    }
  end

  defp time(func, label) do
    {time, result} = :timer.tc(func, :millisecond)
    Logger.info("QuestAnalyzer #{label}: #{time}ms")
    result
  end
end
