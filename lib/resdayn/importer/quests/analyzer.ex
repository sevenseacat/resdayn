defmodule Resdayn.Importer.Quests.Analyzer do
  require Ash.Query

  alias Resdayn.Codex.QuestAnalysis.RelatedItem
  alias Resdayn.Codex.QuestAnalysis.RelatedLocation
  alias Resdayn.Codex.QuestAnalysis.RelatedNPC
  alias Resdayn.Codex.QuestAnalysis.Transition
  alias Resdayn.Importer.Quests.ChoiceChain
  alias Resdayn.Importer.Quests.ItemLocations
  alias Resdayn.Importer.Quests.TopicAvailability

  def analyze(quest_ids \\ []) do
    quests = load_quests(quest_ids)

    script_map = load_script_map()
    dialogue_with_scripts = load_dialogue_with_scripts(script_map)
    script_journals_by_quest_id = load_scripts(script_map)
    all_npcs = load_all_npcs()
    npc_id_set = MapSet.new(all_npcs, fn npc -> downcase(npc.id) end)
    item_locations = load_item_locations()

    # Build topic availability index for inferring from_min bounds
    topic_availability =
      build_topic_availability()
      |> add_script_topic_availability(script_journals_by_quest_id)

    # Build choice presenter index for linking choice-conditioned responses to their parents
    choice_presenters = ChoiceChain.build_index(dialogue_with_scripts)

    Map.new(quests, fn quest ->
      IO.puts("Analyzing #{quest.id}...")

      script_updates =
        Map.get(script_journals_by_quest_id, downcase(quest.id), [])
        |> Enum.map(fn update ->
          %Transition{
            id: Transition.make_id(update.script_id, update.index),
            index: update.index,
            from_max: update.index - 1,
            trigger_type: :script,
            trigger_id: update.script_id
          }
        end)

      # Get script IDs that update this quest
      quest_script_ids =
        script_updates
        |> Enum.map(& &1.trigger_id)
        |> Enum.map(&downcase/1)
        |> MapSet.new()

      # Find NPCs that have these scripts attached
      npcs_with_quest_scripts =
        all_npcs
        |> Enum.filter(fn npc ->
          npc.script_id && MapSet.member?(quest_script_ids, downcase(npc.script_id))
        end)

      dialogue_updates =
        dialogue_with_scripts
        |> Enum.filter(fn dialogue ->
          Map.has_key?(dialogue.script_content, downcase(quest.id))
        end)

      # Build dialogue transitions
      dialogue_transitions =
        dialogue_updates
        |> Enum.flat_map(fn response ->
          quest_commands = Map.get(response.script_content, downcase(quest.id), [])

          quest_commands
          |> Enum.map(fn cmd ->
            {from_min, from_max} = extract_journal_bounds(response.conditions, quest.id)

            # If from_min is nil, check if this is a choice-conditioned response
            from_min = from_min || ChoiceChain.get_from_min(choice_presenters, response, quest.id)

            # If from_min is still nil, check if topic availability constrains it
            from_min =
              apply_topic_availability_bounds(
                from_min,
                response.topic_id,
                quest.id,
                topic_availability
              )

            %Transition{
              id: Transition.make_id(to_string(response.id), cmd.index),
              index: cmd.index,
              from_min: from_min,
              from_max: from_max,
              trigger_type: :dialogue_response,
              trigger_id: Ash.CiString.new(to_string(response.id)),
              trigger_topic_id: response.topic_id
            }
          end)
        end)

      all_transitions =
        (script_updates ++ dialogue_transitions)
        |> narrow_from_ranges(quest.journal_entries)

      # Build per-transition lookups so each transition can resolve its own
      # conditions, effects, and trigger NPCs without rescanning the world.
      effects_by_tid =
        effects_per_transition(
          all_transitions,
          dialogue_updates,
          script_journals_by_quest_id,
          quest.id
        )

      conditions_by_tid = conditions_per_transition(all_transitions, dialogue_updates)

      triggers_by_tid =
        triggers_per_transition(all_transitions, dialogue_updates, npcs_with_quest_scripts)

      # Identify quest-start and quest-finish transitions for role flagging.
      finisher_indices =
        quest.journal_entries
        |> Enum.filter(& &1.finishes_quest)
        |> MapSet.new(& &1.index)

      min_index =
        quest.journal_entries
        |> Enum.map(& &1.index)
        |> Enum.min(fn -> nil end)

      start_transition_ids =
        all_transitions
        |> Enum.filter(&quest_start?(&1, min_index))
        |> MapSet.new(& &1.id)

      finish_transition_ids =
        all_transitions
        |> Enum.filter(fn t -> MapSet.member?(finisher_indices, t.index) end)
        |> MapSet.new(& &1.id)

      # Flat event lists: each event is {entity_id, role, transition_id}.
      npc_events = build_npc_events(all_transitions, triggers_by_tid, effects_by_tid, npc_id_set)
      item_events = build_item_events(all_transitions, conditions_by_tid, effects_by_tid)

      related_npcs =
        build_related_npcs(
          npc_events,
          all_transitions,
          start_transition_ids,
          finish_transition_ids
        )

      related_items = build_related_items(item_events)

      all_quest_npcs =
        related_npcs
        |> Enum.map(fn r -> Enum.find(all_npcs, &(downcase(&1.id) == downcase(r.npc_id))) end)
        |> Enum.filter(& &1)

      topics = Enum.map(dialogue_updates, & &1.topic_id) |> ci_uniq()

      condition_item_ids = extract_condition_item_ids(dialogue_updates)

      add_item_targets =
        collect_add_item_targets(dialogue_updates, script_journals_by_quest_id, quest.id)

      item_location_sources =
        ItemLocations.get_locations(item_locations, condition_item_ids, add_item_targets)

      related_locations =
        build_related_locations(
          all_quest_npcs,
          item_location_sources,
          related_npcs,
          related_items
        )

      {to_string(quest.id),
       %Resdayn.Codex.QuestAnalysis.Analysis{
         quest_id: to_string(quest.id),
         transitions: all_transitions,
         journal_entries: format_journal_entries(quest.journal_entries),
         related_npcs: related_npcs,
         related_locations: related_locations,
         dialogue_topics: topics,
         related_items: related_items
       }}
    end)
  end

  defp load_quests([]) do
    Resdayn.Codex.Dialogue.Quest
    |> Ash.Query.for_read(:read)
    |> Ash.read!(load: [:journal_entries])
  end

  defp load_quests(list) when is_list(list) do
    Resdayn.Codex.Dialogue.Quest
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(id in ^list)
    |> Ash.read!(load: [:journal_entries])
  end

  defp load_item_locations do
    unique_placements = load_unique_placements()
    holders = load_inventory_holders()
    ItemLocations.build(unique_placements, holders)
  end

  # References with exactly 1 cell placement: %{downcased_ref_id => cell_id}
  defp load_unique_placements do
    {:ok, %{rows: rows}} =
      Ecto.Adapters.SQL.query(Resdayn.Repo, """
        SELECT LOWER(reference_id), MIN(cell_id)
        FROM cell_references
        GROUP BY LOWER(reference_id)
        HAVING COUNT(*) = 1
      """)

    Map.new(rows, fn [ref_id, cell_id] -> {ref_id, cell_id} end)
  end

  # Inventory holders grouped by item: %{downcased_item_id => [holder_ref_id]}
  defp load_inventory_holders do
    {:ok, %{rows: rows}} =
      Ecto.Adapters.SQL.query(Resdayn.Repo, """
        SELECT LOWER(object_ref_id), array_agg(DISTINCT LOWER(holder_ref_id))
        FROM inventory_items
        GROUP BY LOWER(object_ref_id)
      """)

    Map.new(rows, fn [item_id, holder_ids] -> {item_id, holder_ids} end)
  end

  defp load_all_npcs do
    Resdayn.Codex.World.NPC
    |> Ash.Query.for_read(:read)
    |> Ash.read!(load: [:cell_id, :cell_name])
  end

  # Build a map of downcased script_id -> text for follow_scripts support
  defp load_script_map do
    Resdayn.Codex.Mechanics.Script
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(not is_nil(text))
    |> Ash.read!()
    |> Map.new(fn script -> {downcase(script.id), script.text} end)
  end

  # Parse all scripts into their journal commands, grouped by quest ID.
  defp load_scripts(script_map) do
    script_map
    |> Enum.flat_map(fn {id, text} ->
      Resdayn.Importer.Quests.ScriptParser.extract_journal_commands(text, script_map,
        follow_scripts: true
      )
      |> Enum.map(&Map.put(&1, :script_id, Ash.CiString.new(id)))
    end)
    |> Enum.group_by(& &1.quest_id)
  end

  defp load_dialogue_with_scripts(script_map) do
    Resdayn.Codex.Dialogue.Response
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(not is_nil(script_content))
    |> Ash.read!()
    |> Enum.map(fn response ->
      Map.update!(
        response,
        :script_content,
        fn script_content ->
          Enum.group_by(
            Resdayn.Importer.Quests.ScriptParser.extract_journal_commands(
              script_content,
              script_map,
              follow_scripts: true
            ),
            & &1.quest_id
          )
        end
      )
    end)
  end

  # Build related items with journal-index linkage. Each item collects all
  # journal indices it is associated with (target indices of triggered/gated
  # journal commands). Reason priority on collision: :required > :surrendered
  # > :received, reflecting how much player action each implies.
  # Per-transition effect lookup: transition_id -> list of effects on that
  # transition's specific journal command.
  defp effects_per_transition(all_transitions, dialogue_updates, script_journals_by_quest_id, quest_id) do
    quest_id_lower = downcase(quest_id)

    dialogue_commands_by_trigger_id =
      Map.new(dialogue_updates, fn response ->
        {downcase(to_string(response.id)), Map.get(response.script_content, quest_id_lower, [])}
      end)

    script_commands_by_trigger_id =
      Map.get(script_journals_by_quest_id, quest_id_lower, [])
      |> Enum.group_by(&downcase(&1.script_id))

    Map.new(all_transitions, fn t ->
      cmds =
        case t.trigger_type do
          :dialogue_response -> Map.get(dialogue_commands_by_trigger_id, downcase(t.trigger_id), [])
          :script -> Map.get(script_commands_by_trigger_id, downcase(t.trigger_id), [])
        end

      effects =
        case Enum.find(cmds, &(&1.index == t.index)) do
          nil -> []
          cmd -> cmd.effects
        end

      {t.id, effects}
    end)
  end

  # Per-transition condition lookup: transition_id -> conditions on the gating
  # response. Script transitions have no conditions.
  defp conditions_per_transition(all_transitions, dialogue_updates) do
    conditions_by_response_id =
      Map.new(dialogue_updates, fn r -> {downcase(to_string(r.id)), r.conditions || []} end)

    Map.new(all_transitions, fn t ->
      conditions =
        case t.trigger_type do
          :dialogue_response -> Map.get(conditions_by_response_id, downcase(t.trigger_id), [])
          :script -> []
        end

      {t.id, conditions}
    end)
  end

  # Per-transition trigger lookup: transition_id -> list of NPC IDs that
  # cause the transition (dialogue speaker or script-bearing NPCs).
  defp triggers_per_transition(all_transitions, dialogue_updates, npcs_with_quest_scripts) do
    speaker_by_response_id =
      Map.new(dialogue_updates, fn r -> {downcase(to_string(r.id)), r.speaker_npc_id} end)

    npcs_by_script_id =
      Enum.group_by(npcs_with_quest_scripts, &downcase(&1.script_id), & &1.id)

    Map.new(all_transitions, fn t ->
      triggers =
        case t.trigger_type do
          :dialogue_response ->
            case Map.get(speaker_by_response_id, downcase(t.trigger_id)) do
              nil -> []
              speaker -> [speaker]
            end

          :script ->
            Map.get(npcs_by_script_id, downcase(t.trigger_id), [])
        end

      {t.id, triggers}
    end)
  end

  # Flat NPC event list: {npc_id, role, transition_id} per occurrence.
  defp build_npc_events(all_transitions, triggers_by_tid, effects_by_tid, npc_id_set) do
    Enum.flat_map(all_transitions, fn t ->
      trigger_events =
        triggers_by_tid
        |> Map.get(t.id, [])
        |> Enum.map(fn npc_id -> {npc_id, :trigger, t.id} end)

      effect_target_events =
        effects_by_tid
        |> Map.get(t.id, [])
        |> Enum.map(fn e -> e[:subject] end)
        |> Enum.filter(fn s -> is_binary(s) and MapSet.member?(npc_id_set, downcase(s)) end)
        |> Enum.map(fn s -> {Ash.CiString.new(s), :effect_target, t.id} end)

      trigger_events ++ effect_target_events
    end)
  end

  # Flat item event list: {item_id, role, transition_id} per occurrence.
  defp build_item_events(all_transitions, conditions_by_tid, effects_by_tid) do
    Enum.flat_map(all_transitions, fn t ->
      conditions = Map.get(conditions_by_tid, t.id, [])
      effects = Map.get(effects_by_tid, t.id, [])

      required =
        conditions
        |> Enum.filter(fn c -> c.function == :item and c.name end)
        |> Enum.map(fn c -> {Ash.CiString.new(c.name), :required, t.id} end)

      received =
        effects
        |> Enum.filter(fn e -> e[:function] == :add_item and e[:subject] == :player end)
        |> Enum.map(fn e -> {Ash.CiString.new(e[:item_id]), :received, t.id} end)

      surrendered =
        effects
        |> Enum.filter(fn e -> e[:function] == :remove_item and e[:subject] == :player end)
        |> Enum.map(fn e -> {Ash.CiString.new(e[:item_id]), :surrendered, t.id} end)

      required ++ received ++ surrendered
    end)
  end

  defp build_related_items(item_events) do
    item_events
    |> Enum.group_by(fn {item_id, _, _} -> downcase(item_id) end)
    |> Enum.map(fn {_key, events} ->
      {first_id, _, _} = hd(events)

      uses =
        events
        |> Enum.map(fn {_, role, tid} -> %{role: role, transition_id: tid} end)
        |> Enum.uniq()

      %RelatedItem{item_id: first_id, uses: uses}
    end)
  end

  defp build_related_npcs(npc_events, all_transitions, start_transition_ids, finish_transition_ids) do
    transition_type_by_tid = Map.new(all_transitions, fn t -> {t.id, t.trigger_type} end)

    npc_events
    |> Enum.group_by(fn {npc_id, _, _} -> downcase(npc_id) end)
    |> Enum.map(fn {_key, events} ->
      {first_npc_id, _, _} = hd(events)

      uses =
        events
        |> Enum.map(fn {_, role, tid} -> %{role: role, transition_id: tid} end)
        |> Enum.uniq()

      reason = derive_npc_reason(events, transition_type_by_tid)

      quest_giver? =
        Enum.any?(events, fn {_, role, tid} ->
          role == :trigger and MapSet.member?(start_transition_ids, tid)
        end)

      quest_finisher? =
        Enum.any?(events, fn {_, role, tid} ->
          role == :trigger and MapSet.member?(finish_transition_ids, tid)
        end)

      %RelatedNPC{
        npc_id: first_npc_id,
        reason: reason,
        uses: uses,
        quest_giver?: quest_giver?,
        quest_finisher?: quest_finisher?
      }
    end)
  end

  # Discovery channel derived from the NPC's uses. An NPC triggering at least
  # one dialogue transition is a :dialogue_speaker; otherwise a :script_bearer
  # if they trigger any script transition; otherwise an :effect_target.
  defp derive_npc_reason(events, transition_type_by_tid) do
    sources =
      events
      |> Enum.map(fn {_, role, tid} ->
        case role do
          :trigger ->
            case Map.get(transition_type_by_tid, tid) do
              :dialogue_response -> :dialogue_speaker
              :script -> :script_bearer
            end

          :effect_target ->
            :effect_target
        end
      end)
      |> MapSet.new()

    cond do
      MapSet.member?(sources, :dialogue_speaker) -> :dialogue_speaker
      MapSet.member?(sources, :script_bearer) -> :script_bearer
      true -> :effect_target
    end
  end

  defp build_related_locations(all_quest_npcs, item_locations, related_npcs, related_items) do
    npc_uses_by_id = Map.new(related_npcs, fn n -> {downcase(n.npc_id), n.uses} end)
    item_uses_by_id = Map.new(related_items, fn i -> {downcase(i.item_id), i.uses} end)

    from_npcs =
      all_quest_npcs
      |> Enum.filter(& &1.cell_id)
      |> Enum.map(fn npc -> {Ash.CiString.new(npc.cell_id), {:npc, npc.id}} end)

    from_items =
      Enum.map(item_locations, fn {cell_id, item_id} -> {cell_id, {:item, item_id}} end)

    (from_npcs ++ from_items)
    |> Enum.group_by(fn {cell, _} -> downcase(cell) end)
    |> Enum.map(fn {_key, entries} ->
      {first_cell, _} = hd(entries)

      npc_ids =
        entries
        |> Enum.flat_map(fn
          {_, {:npc, id}} -> [id]
          _ -> []
        end)
        |> Enum.uniq_by(&downcase/1)

      item_ids =
        entries
        |> Enum.flat_map(fn
          {_, {:item, id}} -> [id]
          _ -> []
        end)
        |> Enum.uniq_by(&downcase/1)

      transition_ids =
        (Enum.flat_map(npc_ids, fn id -> Map.get(npc_uses_by_id, downcase(id), []) end) ++
           Enum.flat_map(item_ids, fn id -> Map.get(item_uses_by_id, downcase(id), []) end))
        |> Enum.map(& &1.transition_id)
        |> Enum.uniq()

      %RelatedLocation{
        cell_id: first_cell,
        npc_ids: npc_ids,
        item_ids: item_ids,
        transition_ids: transition_ids
      }
    end)
  end

  defp extract_condition_item_ids(dialogue_updates) do
    dialogue_updates
    |> Enum.flat_map(fn response ->
      (response.conditions || [])
      |> Enum.filter(fn c -> c.function == :item end)
      |> Enum.map(fn c -> c.name end)
    end)
    |> Enum.uniq()
  end

  # Collect add_item effect targets: returns %{downcased_item_id => [target_ids]}.
  # Used by ItemLocations to resolve where quest items live in the world.
  defp collect_add_item_targets(dialogue_updates, script_journals_by_quest_id, quest_id) do
    dialogue_effects =
      dialogue_updates
      |> Enum.flat_map(fn response ->
        Map.get(response.script_content, downcase(quest_id), [])
        |> Enum.flat_map(& &1.effects)
      end)

    script_effects =
      Map.get(script_journals_by_quest_id, downcase(quest_id), [])
      |> Enum.flat_map(& &1.effects)

    (dialogue_effects ++ script_effects)
    |> Enum.filter(fn e -> e[:function] == :add_item and is_binary(e[:subject]) end)
    |> Enum.group_by(fn e -> downcase(e[:item_id]) end, fn e -> e[:subject] end)
  end

  defp format_journal_entries(entries) do
    entries
    |> Enum.sort_by(& &1.index)
    |> Enum.map(fn entry ->
      %{
        index: entry.index,
        content: entry.content,
        finish?: entry.finishes_quest,
        restart?: entry.restarts_quest
      }
    end)
  end

  defp extract_journal_bounds(conditions, quest_id) do
    quest_id_lower = downcase(quest_id)

    journal_conditions =
      (conditions || [])
      |> Enum.filter(fn c ->
        c.function == :journal && downcase(c.name) == quest_id_lower
      end)

    from_min =
      journal_conditions
      |> Enum.filter(fn c -> c.operator in [:>=, :>, :=] end)
      |> Enum.map(fn c ->
        value = c.value.value
        if c.operator == :>, do: value + 1, else: value
      end)
      |> Enum.max(fn -> nil end)

    from_max =
      journal_conditions
      |> Enum.filter(fn c -> c.operator in [:<=, :<, :=] end)
      |> Enum.map(fn c ->
        value = c.value.value
        if c.operator == :<, do: value - 1, else: value
      end)
      |> Enum.min(fn -> nil end)

    {from_min, from_max}
  end

  defp build_topic_availability do
    # Load all topic IDs for implicit topic detection
    all_topic_ids =
      Resdayn.Codex.Dialogue.Topic
      |> Ash.Query.for_read(:read)
      |> Ash.read!()
      |> Enum.map(&to_string(&1.id))

    # Load all dialogue responses (not just those with scripts)
    all_responses =
      Resdayn.Codex.Dialogue.Response
      |> Ash.Query.for_read(:read)
      |> Ash.read!()

    TopicAvailability.build(all_responses, all_topic_ids, parallel: true)
  end

  # When a standalone script sets a journal index AND adds a topic, we know
  # that topic becomes available at that journal index.
  defp add_script_topic_availability(topic_availability, script_journals_by_quest_id) do
    entries =
      script_journals_by_quest_id
      |> Enum.flat_map(fn {quest_id, commands} ->
        Enum.flat_map(commands, fn cmd ->
          cmd.effects
          |> Enum.filter(fn e -> e[:function] == :add_topic end)
          |> Enum.map(fn e ->
            %{
              topic_id: String.downcase(e[:topic_id]),
              quest_id: quest_id,
              from_min: cmd.index,
              from_max: nil,
              source: :script
            }
          end)
        end)
      end)

    TopicAvailability.add_entries(topic_availability, entries)
  end

  # Narrow from ranges using known journal indices:
  # - If a range (e.g. 10-19) contains only one journal index, pin to that index
  # - If from_max is set but no journal indices exist in 0..from_max, this is the
  #   quest start point (from_min: 0, from_max: 0)
  defp narrow_from_ranges(transitions, journal_entries) do
    known_indices = MapSet.new(journal_entries, & &1.index)

    Enum.map(transitions, fn transition ->
      narrow_from_range(transition, known_indices)
    end)
  end

  defp narrow_from_range(%{from_max: from_max} = transition, known_indices)
       when not is_nil(from_max) do
    from_min = transition.from_min || 0

    indices_in_range =
      known_indices
      |> Enum.filter(fn i -> i >= from_min and i <= from_max end)

    case indices_in_range do
      [] -> %{transition | from_min: 0, from_max: 0}
      [single] -> %{transition | from_min: single, from_max: single}
      _ -> transition
    end
  end

  defp narrow_from_range(transition, _known_indices), do: transition

  defp apply_topic_availability_bounds(from_min, topic_id, quest_id, topic_availability) do
    {topic_from_min, _topic_from_max} =
      TopicAvailability.get_bounds(topic_availability, topic_id, quest_id)

    case {from_min, topic_from_min} do
      # If we already have a from_min, take the max of the two
      {existing, topic_min} when not is_nil(existing) and not is_nil(topic_min) ->
        max(existing, topic_min)

      # If only topic has a min, use it
      {nil, topic_min} when not is_nil(topic_min) ->
        topic_min

      # Otherwise keep what we have (which may be nil)
      {existing, _} ->
        existing
    end
  end

  # A transition is the quest's entry point if it advances to the earliest
  # journal index AND its precondition is compatible with quest state 0.
  # `from_max == 0` catches narrowed starts (e.g. script triggers with index 1
  # whose from_max gets pinned by `narrow_from_ranges`). `from_max == nil`
  # catches unconditioned dialogue that simply lacks any journal precondition.
  defp quest_start?(transition, min_index) do
    transition.index == min_index and
      transition.from_min in [nil, 0] and
      transition.from_max in [nil, 0]
  end

  defp ci_uniq(list), do: Enum.uniq_by(list, &downcase/1)

  defp downcase(%Ash.CiString{} = value), do: String.downcase(to_string(value))
  defp downcase(value) when is_binary(value), do: String.downcase(value)
end
