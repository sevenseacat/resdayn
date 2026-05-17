output_dir = "quest_analysis"
File.mkdir_p!(output_dir)

{time, results} = :timer.tc(fn -> Resdayn.Importer.Quests.Analyzer.analyze() end)

for {_key, analysis} <- Enum.sort_by(results, fn {k, _} -> k end) do
  journal_lines =
    Enum.map(analysis.journal_entries, fn entry ->
      flags =
        [if(entry.finish?, do: "FINISH"), if(entry.restart?, do: "RESTART")]
        |> Enum.filter(& &1)
        |> Enum.join(", ")

      flag_str = if flags != "", do: " [#{flags}]", else: ""
      "- **#{entry.index}**: #{entry.content}#{flag_str}"
    end)

  transition_lines =
    analysis.transitions
    |> Enum.sort_by(& &1.index)
    |> Enum.map(fn t ->
      from =
        case {t.from_min, t.from_max} do
          {nil, nil} -> "?"
          {min, nil} -> "#{min}+"
          {nil, max} -> "0-#{max}"
          {min, max} when min == max -> "#{min}"
          {min, max} -> "#{min}-#{max}"
        end

      topic = if t.trigger_topic_id, do: " topic:#{t.trigger_topic_id}", else: ""
      "- #{from} → **#{t.index}** (#{t.trigger_type}#{topic})"
    end)

  section = fn title, items ->
    if items != [] do
      ["", "## #{title}", "" | Enum.map(items, &"- #{&1}")]
    else
      []
    end
  end

  lines =
    ["# #{analysis.quest_id}"] ++
      section.(
        "Related NPCs",
        Enum.map(analysis.related_npcs, &"#{&1.npc_id} (#{&1.reason})")
      ) ++
      section.("Key Items", analysis.key_items) ++
      section.("Key Locations", analysis.key_locations) ++
      section.("Dialogue Topics", analysis.dialogue_topics) ++
      ["", "## Journal Entries", ""] ++
      journal_lines ++
      ["", "## Transitions", ""] ++
      transition_lines

  content = Enum.join(lines, "\n") <> "\n"
  path = Path.join(output_dir, "#{analysis.quest_id}.md")
  File.write!(path, content)
end

quest_count = map_size(results)
IO.puts("\nAnalyzed #{quest_count} quests in #{div(time, 1000)}ms")
IO.puts("Output written to #{output_dir}/")
