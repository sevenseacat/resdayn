defmodule Resdayn.Importer.Quests.ScriptParser do
  @moduledoc """
  Parse raw script content into its AST form, ready for analysis.
  """

  alias Resdayn.Importer.Quests.Script

  def parse(content) when is_binary(content) do
    lines = parse_input(content)

    {name, locals, _lines} = parse_header(lines)

    %Script.Ast{
      name: name,
      locals: locals,
      body: parse_body(lines, locals)
    }
  end

  defp parse_header(lines, data \\ {nil, [], []})

  defp parse_header(["begin " <> name | lines], {nil, [], []}) do
    parse_header(lines, {name, [], []})
  end

  defp parse_header(["short " <> short | lines], {name, locals, []}) do
    parse_header(lines, {name, [short | locals], []})
  end

  defp parse_header(["long " <> long | lines], {name, locals, []}) do
    parse_header(lines, {name, [long | locals], []})
  end

  defp parse_header(lines, {name, locals, []}) do
    {name, Enum.reverse(locals), lines}
  end

  # ============================================================================
  # Line Parser
  # ============================================================================

  defp parse_body(lines, locals) do
    parse_body(lines, locals, [])
  end

  defp parse_body([], _locals, acc), do: Enum.reverse(acc)

  defp parse_body([line | lines], locals, acc) do
    if String.starts_with?(line, "if") do
      {block, rest} = parse_if_block(line, lines, locals)
      parse_body(rest, locals, [block | acc])
    else
      item = parse_single_line(line)
      parse_body(lines, locals, maybe_cons(item, acc))
    end
  end

  defp parse_if_block(line, lines, locals) do
    condition = parse_condition(line, locals)
    {body, else_clause, rest} = parse_block_body(lines, locals, [])

    block = %Script.IfBlock{
      condition: condition,
      body: body,
      else_clause: else_clause
    }

    {block, rest}
  end

  defp parse_block_body([], _locals, acc) do
    # Unbalanced - return what we have
    {Enum.reverse(acc), nil, []}
  end

  defp parse_block_body([line | lines], locals, acc) do
    cond do
      String.starts_with?(line, "endif") ->
        {Enum.reverse(acc), nil, lines}

      String.starts_with?(line, "elseif") ->
        {block, rest} = parse_if_block(line, lines, locals)
        {Enum.reverse(acc), block, rest}

      String.starts_with?(line, "else") ->
        {else_body, _, rest} = parse_block_body(lines, locals, [])
        {Enum.reverse(acc), else_body, rest}

      String.starts_with?(line, "if") ->
        {block, rest} = parse_if_block(line, lines, locals)
        parse_block_body(rest, locals, [block | acc])

      true ->
        # No keywords - a journal, effect, etc.
        item = parse_single_line(line)
        parse_block_body(lines, locals, maybe_cons(item, acc))
    end
  end

  defp parse_single_line(line) do
    cond do
      String.starts_with?(line, "journal ") ->
        {quest_id, index} = parse_journal_command(line)
        %Script.Journal{quest_id: quest_id, index: index}

      true ->
        case parse_effect(line) do
          nil ->
            nil

          effect ->
            %Script.Effect{function: effect.function, data: Map.drop(effect, [:function])}
        end
    end
  end

  # ============================================================================
  # Recursive walker to collect journal commands
  # ============================================================================

  def extract_journal_commands(content, script_map \\ %{}, opts \\ [])

  def extract_journal_commands(content, script_map, opts) when is_binary(content) do
    extract_journal_commands(parse(content), script_map, opts)
  end

  def extract_journal_commands(ast, script_map, opts) do
    state = %{
      conditions: [],
      inherited_effects: [],
      journals: [],
      script_map: script_map,
      follow_scripts: Keyword.get(opts, :follow_scripts, false),
      visited: MapSet.new()
    }

    result = walk_body(ast.body, state)

    # This still has the start_script/stop_script commands in it
    # Strip them out as we don't need them
    result.journals
    |> Enum.map(fn entry ->
      Map.update!(entry, :effects, fn effects ->
        Enum.reject(effects, fn effect ->
          effect.function in [:start_script, :stop_script]
        end)
      end)
    end)
  end

  # Walk a list of AST nodes (a block body)
  #
  # Two-pass approach:
  # 1. First pass: collect ALL effects at this level (including from StartScript)
  # 2. Second pass: create journal entries and recurse into nested blocks
  #
  # This is done in two passes because nested blocks should only get the effects
  # that appear before the block, but effects after the nested block should get
  # all the effects from the same level
  defp walk_body(nodes, state) do
    # Pass 1: Collect all effects at this level
    {level_effects, state} = collect_effects(nodes, state)

    # All effects for journals at this level = inherited + this level's
    all_effects = state.inherited_effects ++ level_effects

    # Pass 2: Process journals and recurse into nested blocks
    # For nested blocks, we pass cumulative effects up to that point
    {final_state, _cumulative} =
      Enum.reduce(nodes, {state, state.inherited_effects}, fn node, {s, cumulative} ->
        case node do
          %Script.Journal{} = journal ->
            entry = %{
              quest_id: journal.quest_id,
              index: journal.index,
              conditions: s.conditions,
              effects: all_effects
            }

            {%{s | journals: s.journals ++ [entry]}, cumulative}

          %Script.IfBlock{} = block ->
            # Nested block inherits effects accumulated SO FAR (not all level effects)
            s = walk_if_block(block, %{s | inherited_effects: cumulative})
            {s, cumulative}

          %Script.Effect{} = effect ->
            # Add to cumulative for future nested blocks
            effect_data = Map.put(effect.data, :function, effect.function)
            {s, cumulative ++ [effect_data]}

          _ ->
            {s, cumulative}
        end
      end)

    final_state
  end

  # Collect all effects at this level, following StartScript if enabled
  defp collect_effects(nodes, state) do
    Enum.reduce(nodes, {[], state}, fn node, {effects, s} ->
      case node do
        %Script.Effect{} = effect ->
          effect_data = Map.put(effect.data, :function, effect.function)

          # Follow StartScript and collect its top-level effects
          {followed_effects, s} =
            if effect.function == :start_script and s.follow_scripts do
              collect_from_start_script(effect.data.script_id, s)
            else
              {[], s}
            end

          {effects ++ [effect_data] ++ followed_effects, s}

        _ ->
          {effects, s}
      end
    end)
  end

  defp walk_if_block(%Script.IfBlock{} = block, state) do
    # Process the "if" branch
    state = process_branch(block.condition, block.body, state)

    # Process else clause if present
    case block.else_clause do
      nil ->
        state

      %Script.IfBlock{} = elseif_block ->
        walk_if_block(elseif_block, state)

      else_body when is_list(else_body) ->
        process_branch(nil, else_body, state)
    end
  end

  # Process a branch (if body, elseif body, or else body)
  defp process_branch(condition, body, state) do
    child_conditions =
      if condition do
        state.conditions ++ [condition]
      else
        state.conditions
      end

    child_state = %{
      state
      | conditions: child_conditions,
        journals: []
    }

    result = walk_body(body, child_state)

    # Merge child's journals into parent (effects don't leak back up)
    %{state | journals: state.journals ++ result.journals}
  end

  # Follow a StartScript and collect its top-level effects only
  defp collect_from_start_script(script_id, state) do
    script_key = String.downcase(script_id)

    if MapSet.member?(state.visited, script_key) do
      {[], state}
    else
      case Map.get(state.script_map, script_key) do
        nil ->
          {[], state}

        script_text when is_binary(script_text) ->
          ast = parse(script_text)
          collect_top_level_effects(ast.body, state, script_key)

        %{body: body} ->
          collect_top_level_effects(body, state, script_key)
      end
    end
  end

  # Collect only TOP-LEVEL effects from a script body (don't recurse into if blocks)
  defp collect_top_level_effects(body, state, script_key) do
    state = %{state | visited: MapSet.put(state.visited, script_key)}

    Enum.reduce(body, {[], state}, fn node, {effects, s} ->
      case node do
        %Script.Effect{} = effect ->
          effect_data = Map.put(effect.data, :function, effect.function)

          # Recursively follow nested StartScripts
          {followed, s} =
            if effect.function == :start_script and s.follow_scripts do
              collect_from_start_script(effect.data.script_id, s)
            else
              {[], s}
            end

          {effects ++ [effect_data] ++ followed, s}

        # Ignore IfBlocks and Journals in called scripts
        _ ->
          {effects, s}
      end
    end)
  end

  # ============================================================================
  # Journal Command Parsing
  # ============================================================================

  # Quest ID may be quoted or not
  def parse_journal_command(<<"journal "::binary, line::binary>>) do
    line = String.replace(line, "\"", "")
    words = String.split(line, " ")
    {index, quest_id} = List.pop_at(words, -1)
    {Enum.join(quest_id, " "), String.to_integer(index)}
  end

  def parse_journal_command(_), do: nil

  # ============================================================================
  # Condition Parsing
  # ============================================================================

  def parse_condition(line, locals \\ []) do
    line = Regex.replace(~r/(if|elseif|while|\(|\))/i, line, "")

    Regex.replace(~r/\s+/, line, " ")
    |> String.trim()
    |> do_parse_condition(locals)
  end

  defp do_parse_condition(line, locals) do
    case parse_subject(line) do
      {subject, line} ->
        case String.trim(line) do
          <<"getjournalindex"::binary, line::binary>> ->
            parse_comparison(line, subject, :journal_index)
            |> Map.delete(:subject)

          <<"getdeadcount"::binary, line::binary>> ->
            parse_comparison(line, subject, :dead_count)
            |> Map.delete(:subject)

          <<"getitemcount"::binary, line::binary>> ->
            parse_comparison(line, subject, :item_count)

          <<"getinterior"::binary, line::binary>> ->
            parse_rhs(line, subject, :interior)

          <<"getpccell"::binary, line::binary>> ->
            parse_comparison(line, subject, :pc_cell)
            |> Map.delete(:subject)

          <<"ondeath"::binary, line::binary>> ->
            parse_rhs(line, subject, :on_death)

          <<"onactivate"::binary, line::binary>> ->
            parse_rhs(line, subject, :on_activate)

          <<"getdisabled"::binary, line::binary>> ->
            parse_rhs(line, subject, :disabled)

          <<"getdistance"::binary, line::binary>> ->
            parse_comparison(line, subject, :distance)

          <<"gethealth"::binary, line::binary>> ->
            parse_rhs(line, subject, :health)

          <<"getpcrank"::binary, line::binary>> ->
            parse_comparison(line, subject, :pc_rank)

          <<"getspell"::binary, line::binary>> ->
            parse_comparison(line, subject, :knows_spell)

          <<"getblightdisease"::binary, line::binary>> ->
            parse_rhs(line, subject, :blight_disease)

          <<"getcommondisease"::binary, line::binary>> ->
            parse_rhs(line, subject, :common_disease)

          <<"getcurrentaipackage"::binary, line::binary>> ->
            parse_rhs(line, subject, :current_ai_package)

          <<"menumode"::binary, line::binary>> ->
            parse_rhs(line, subject, :menu_mode)

          <<"cellchanged"::binary, line::binary>> ->
            parse_rhs(line, subject, :cell_changed)

          <<"iswerewolf"::binary, line::binary>> ->
            parse_rhs(line, subject, :is_werewolf)

          <<"getrace"::binary, line::binary>> ->
            parse_comparison(line, subject, :race)

          <<"hassoulgem"::binary, line::binary>> ->
            parse_comparison(line, subject, :has_soul_gem)

          <<"getlocked"::binary, line::binary>> ->
            parse_rhs(line, subject, :locked)

          <<"scriptrunning"::binary, line::binary>> ->
            parse_comparison(line, subject, :script_running)

          <<"pcexpelled"::binary, line::binary>> ->
            parse_comparison(line, subject, :expelled)

          <<"getattacked"::binary, line::binary>> ->
            parse_rhs(line, subject, :attacked)

          <<"geteffect"::binary, line::binary>> ->
            parse_comparison(line, subject, :effect)

          <<"gamehour"::binary, line::binary>> ->
            parse_rhs(line, subject, :game_hour)

          <<"getmagicka"::binary, line::binary>> ->
            parse_rhs(line, subject, :magicka)

          <<"onmurder"::binary, line::binary>> ->
            parse_rhs(line, subject, :on_murder)

          <<"getfatigue"::binary, line::binary>> ->
            parse_rhs(line, subject, :fatigue)

          <<"onpchitme"::binary, line::binary>> ->
            parse_rhs(line, subject, :on_pc_hit_me)

          <<"getcollidingactor"::binary, line::binary>> ->
            parse_rhs(line, subject, :colliding_actor)

          <<"getlevel"::binary, line::binary>> ->
            parse_rhs(line, subject, :level)

          <<"getaipackagedone"::binary, line::binary>> ->
            parse_rhs(line, subject, :ai_package_done)

          <<"onpcequip"::binary, line::binary>> ->
            parse_rhs(line, subject, :on_pc_equip)

          <<"random "::binary, line::binary>> ->
            parse_comparison(line, subject, :random)
            |> Map.update!(:target, &String.to_integer/1)

          <<"getcurrentweather"::binary, line::binary>> ->
            parse_rhs(line, subject, :current_weather)

          <<"getbuttonpressed"::binary, line::binary>> ->
            parse_rhs(line, subject, :button_pressed)

          <<"getlos"::binary, line::binary>> ->
            parse_comparison(line, subject, :line_of_sight)

          <<"getweapondrawn"::binary, line::binary>> ->
            parse_rhs(line, subject, :weapon_drawn)

          <<"getsoundplaying"::binary, line::binary>> ->
            parse_comparison(line, subject, :sound_playing)

          <<"dayspassed"::binary, line::binary>> ->
            parse_rhs(line, subject, :days_passed)

          <<"getcollidingpc"::binary, line::binary>> ->
            parse_rhs(line, subject, :colliding_pc)

          <<"getstandingactor"::binary, line::binary>> ->
            parse_rhs(line, subject, :standing_actor)

          <<"saydone"::binary, line::binary>> ->
            parse_rhs(line, subject, :say_done)

          <<"getdetected"::binary, line::binary>> ->
            parse_comparison(line, subject, :detected)

          <<"getdisposition"::binary, line::binary>> ->
            parse_rhs(line, subject, :disposition)

          <<"getwaterlevel"::binary, line::binary>> ->
            parse_rhs(line, subject, :water_level)

          <<"getpos"::binary, line::binary>> ->
            parse_comparison(line, subject, :position)

          <<"getwerewolfkills"::binary, line::binary>> ->
            parse_rhs(line, subject, :werewolf_kills)

          <<"gettarget"::binary, line::binary>> ->
            parse_comparison(line, subject, :target)

          <<"onknockout"::binary, line::binary>> ->
            parse_rhs(line, subject, :on_knockout)

          <<"getstandingpc"::binary, line::binary>> ->
            parse_rhs(line, subject, :standing_pc)

          <<"hasitemequipped"::binary, line::binary>> ->
            parse_comparison(line, subject, :has_item_equipped)

          _ ->
            result = parse_comparison(line, subject, :local_var)

            # the target could also be an arithmetic expression - check if it uses locals
            variables = Regex.run(~r/\w+/, result.target)

            if Enum.all?(variables, &(&1 in locals)) do
              result
            else
              nil
            end
        end

      line ->
        %{function: :unknown, content: line}
    end
  end

  defp parse_comparison(line, subject, key) do
    case Regex.run(~r/^\s*["]?([^"]+)["]?\s+([<>=!]+)\s*(-?\d+|\w+)/i, line) ||
           Regex.run(~r/^\s*["]?([^"]+)["]?/i, line) do
      [_, target, op, value] ->
        value =
          case Integer.parse(value) do
            {num, ""} -> num
            :error -> value
          end

        %{
          subject: normalize_subject(subject),
          function: key,
          target: target,
          operator: parse_operator(op),
          value: value
        }

      # Implicit "is true, == 1"
      [_, target] ->
        %{
          subject: normalize_subject(subject),
          function: key,
          target: target,
          operator: :==,
          value: 1
        }

      # Something that can't be parsed
      _ ->
        %{
          function: :unknown,
          content: String.trim(line)
        }
    end
  end

  defp parse_rhs(line, subject, key) do
    case Regex.run(~r/^\s*([<>=!]{1,2})\s*(-?\d+|\w+)/, line) do
      [_, operator, value] ->
        value =
          case Integer.parse(value) do
            {num, ""} -> num
            :error -> value
          end

        %{
          subject: normalize_subject(subject),
          function: key,
          operator: parse_operator(operator),
          value: value
        }

      nil ->
        %{
          subject: normalize_subject(subject),
          function: key,
          operator: :==,
          value: 1
        }
    end
  end

  # ============================================================================
  # Effect Parsing
  # ============================================================================

  def parse_effect(line) do
    []
    |> maybe_add_effect(parse_inventory_change(line, "additem", :add_item))
    |> maybe_add_effect(parse_inventory_change(line, "removeitem", :remove_item))
    |> maybe_add_effect(parse_inventory_change(line, "drop", :drop_item))
    |> maybe_add_effect(parse_mod_fac_rep(line))
    |> maybe_add_effect(parse_command_with_string(line, "pcraiserank", :raise_rank, "player"))
    |> maybe_add_effect(parse_command_with_string(line, "pcjoinfaction", :join_faction, "player"))
    |> maybe_add_effect(parse_command_with_number(line, "modreputation", :mod_reputation))
    |> maybe_add_effect(parse_command_with_number(line, "moddisposition", :mod_disposition))
    |> maybe_add_effect(parse_command_with_number(line, "setdisposition", :set_disposition))
    |> maybe_add_effect(parse_add_topic(line))
    |> maybe_add_effect(parse_command(line, "enable", :enable))
    |> maybe_add_effect(parse_command(line, "disable", :disable))
    |> maybe_add_effect(parse_command_with_string(line, "addspell", :add_spell))
    |> maybe_add_effect(parse_command_with_string(line, "removespell", :remove_spell))
    |> maybe_add_effect(parse_command(line, "forcegreeting", :force_greeting))
    |> maybe_add_effect(parse_goodbye(line))
    |> maybe_add_effect(parse_command_with_number(line, "setfight", :set_fight))
    |> maybe_add_effect(parse_command_with_number(line, "setflee", :set_flee))
    |> maybe_add_effect(parse_command_with_number(line, "setalarm", :set_alarm))
    |> maybe_add_effect(parse_command_with_number(line, "sethello", :set_hello))
    |> maybe_add_effect(parse_start_script(line))
    |> maybe_add_effect(parse_stop_script(line))
    |> maybe_add_effect(parse_command_with_string(line, "startcombat", :start_combat))
    |> maybe_add_effect(parse_command(line, "stopcombat", :stop_combat))
    |> maybe_add_effect(parse_ai_follow(line))
    |> maybe_add_effect(parse_ai_travel(line))
    |> maybe_add_effect(parse_ai_wander(line))
    |> maybe_add_effect(parse_ai_escort(line))
    |> maybe_add_effect(parse_command_with_number(line, "lock", :lock))
    |> maybe_add_effect(parse_command(line, "unlock", :unlock))
    |> maybe_add_effect(parse_place_at_pc(line))
    |> maybe_add_effect(parse_position_cell(line))
    |> maybe_add_effect(parse_command_with_number(line, "modstrength", :mod_strength))
    |> maybe_add_effect(parse_command_with_number(line, "modintelligence", :mod_intelligence))
    |> maybe_add_effect(parse_command_with_number(line, "modwillpower", :mod_willpower))
    |> maybe_add_effect(parse_command_with_number(line, "modendurance", :mod_endurance))
    |> maybe_add_effect(parse_command_with_number(line, "modspeed", :mod_speed))
    |> maybe_add_effect(parse_command_with_number(line, "modagility", :mod_agility))
    |> maybe_add_effect(parse_command_with_number(line, "modluck", :mod_luck))
    |> maybe_add_effect(parse_command_with_number(line, "modpersonality", :mod_personality))
    |> List.first()
  end

  defp maybe_add_effect(effects, nil), do: effects
  defp maybe_add_effect(effects, effect), do: effects ++ [effect]

  defp parse_inventory_change(line, check, key) do
    if String.contains?(line, check) do
      {subject, rest} = parse_subject(line)
      {item, count} = parse_item_and_count(rest, check)
      %{count: count, function: key, subject: normalize_subject(subject), item_id: item}
    else
      nil
    end
  end

  defp parse_mod_fac_rep(line) do
    case Regex.run(~r/modpcfacrep\s+([+-]?\d+)\s+["]?([^"\n]+)["]?/i, line) do
      [_, amount, faction] ->
        %{
          function: :mod_faction_reputation,
          faction_id: faction,
          value: String.to_integer(amount)
        }

      nil ->
        nil
    end
  end

  defp parse_subject(line) do
    case String.split(line, "->") do
      # Explicit subject
      [subject, rest] ->
        {subject, rest}

      # Implicit subject - self
      [rest] ->
        {nil, rest}

      _ ->
        # Something else - multiple subjects?
        line
    end
  end

  # eg. ""gold_001" 100", "bk_the_thing 2", ""item with words""
  defp parse_item_and_count(string, check) do
    words =
      string
      |> String.trim_leading("#{check} ")
      |> String.replace("\"", "")
      |> String.split(" ")

    # There may be a count at the end - if not, it's 1
    case Integer.parse(List.last(words)) do
      {count, ""} -> {words |> Enum.drop(-1) |> Enum.join(" "), count}
      _ -> {Enum.join(words, " "), 1}
    end
  end

  defp parse_add_topic(line) do
    case Regex.run(~r/addtopic\s+["]?([^"\n]+)["]?/i, line) do
      [_, topic] -> %{function: :add_topic, topic_id: String.trim(topic)}
      nil -> nil
    end
  end

  defp parse_goodbye("goodbye"), do: %{function: :goodbye}
  defp parse_goodbye(_), do: nil

  defp parse_command_with_number(line, check, key) do
    {subject, rest} = parse_subject(line)

    case Regex.run(~r/#{check}\s+([+-]?\s?\d+)/i, rest) do
      [_, value] ->
        value = String.replace(value, " ", "")
        %{subject: normalize_subject(subject), function: key, value: String.to_integer(value)}

      nil ->
        nil
    end
  end

  defp parse_command_with_string(line, check, key, subject_override \\ nil) do
    {subject, line} = parse_subject(line)

    if String.contains?(line, check) do
      value = line |> String.trim_leading(check) |> String.trim()

      %{
        subject: normalize_subject(subject_override || subject),
        function: key,
        value: normalize_value(value)
      }
    else
      nil
    end
  end

  defp parse_command(line, check, key) do
    {subject, rest} = parse_subject(line)

    if rest == check do
      %{subject: normalize_subject(subject), function: key}
    else
      nil
    end
  end

  defp parse_start_script(line) do
    case Regex.run(~r/startscript\s+["]?([^"\s\n]+)["]?/i, line) do
      [_, script_id] -> %{function: :start_script, script_id: normalize_value(script_id)}
      nil -> nil
    end
  end

  defp parse_stop_script(line) do
    case Regex.run(~r/stopscript\s+["]?([^"\s\n]+)["]?/i, line) do
      [_, script_id] -> %{function: :stop_script, script_id: normalize_value(script_id)}
      nil -> nil
    end
  end

  defp parse_ai_follow(line) do
    {subject, line} = parse_subject(line)

    case Regex.run(~r/aifollow ["]([^"]+)["]/i, line) ||
           Regex.run(~r/aifollow ([^"\s]+)/i, line) do
      [_, target] ->
        %{
          function: :ai_follow,
          subject: normalize_subject(subject),
          target: normalize_subject(target)
        }

      nil ->
        nil
    end
  end

  defp parse_ai_travel(line) do
    {subject, line} = parse_subject(line)

    case Regex.run(~r/aitravel (-?\d+) (-?\d+) (-?\d+)/i, line) do
      [_, x, y, z] ->
        %{
          function: :ai_travel,
          subject: normalize_subject(subject),
          target: %{x: String.to_integer(x), y: String.to_integer(y), z: String.to_integer(z)}
        }

      nil ->
        nil
    end
  end

  defp parse_ai_wander(line) do
    {subject, line} = parse_subject(line)

    case Regex.run(~r/aiwander (\d+)/i, line) do
      [_, range] ->
        %{
          function: :ai_wander,
          subject: normalize_subject(subject),
          range: String.to_integer(range)
        }

      nil ->
        nil
    end
  end

  defp parse_ai_escort(line) do
    {subject, line} = parse_subject(line)

    case Regex.run(~r/aiescort player (-?\d+) (-?\d+) (-?\d+) (-?\d+)/i, line) do
      [_, duration, x, y, z] ->
        %{
          function: :ai_escort,
          subject: normalize_subject(subject),
          target: :player,
          duration: String.to_integer(duration),
          destination: %{
            x: String.to_integer(x),
            y: String.to_integer(y),
            z: String.to_integer(z)
          }
        }

      nil ->
        nil
    end
  end

  defp parse_place_at_pc(line) do
    {subject, line} = parse_subject(line)

    case Regex.run(~r/placeatpc ["]([^"]+)["]/i, line) ||
           Regex.run(~r/placeatpc ([^"\s]+)/i, line) do
      [_, value] ->
        %{
          function: :place_at_pc,
          subject: normalize_subject(subject),
          value: normalize_value(value)
        }

      nil ->
        nil
    end
  end

  defp parse_position_cell(line) do
    {subject, line} = parse_subject(line)

    case Regex.run(~r/positioncell .* ["']([^"']+)["']/i, line) do
      [_, value] ->
        %{
          function: :position_cell,
          subject: normalize_subject(subject),
          value: normalize_value(value)
        }

      nil ->
        nil
    end
  end

  # ============================================================================
  # Helpers
  # ============================================================================

  # Convert the raw script content into a set of slightly more normalized line strings.
  # Removes blank lines, comments, extra whitespace, and optional commas.
  defp parse_input(content) do
    content
    |> String.replace("\r\n", "\n")
    |> String.replace("\r", "\n")
    |> String.split("\n", trim: true)
    |> Enum.map(fn line ->
      case String.split(line, ";", parts: 2) do
        [line] -> line
        [line, _rest] -> line
      end
      |> String.trim()
      |> String.downcase()
      |> strip_commas_outside_quotes()
    end)
    |> Enum.reject(fn line -> String.starts_with?(line, ";") || line == "" end)
  end

  # Strip commas only outside of quoted strings - they're valid inside them,
  # such as cell names like "Ebonheart, Argonian Mission"
  defp strip_commas_outside_quotes(line) do
    line
    |> String.split("\"")
    |> Enum.with_index()
    |> Enum.map(fn {segment, index} ->
      if rem(index, 2) == 0 do
        segment
        |> String.replace(", ", " ")
        |> String.replace(",", " ")
      else
        segment
      end
    end)
    |> Enum.join("\"")
  end

  defp parse_operator("<=="), do: :<=
  defp parse_operator(op), do: String.to_existing_atom(op)

  defp normalize_subject("player"), do: :player
  defp normalize_subject(nil), do: :self
  defp normalize_subject(""), do: :self
  defp normalize_subject(other), do: String.replace(other, "\"", "")

  defp normalize_value(nil), do: nil
  defp normalize_value(""), do: nil
  defp normalize_value(other), do: String.replace(other, "\"", "")

  defp maybe_cons(nil, acc), do: acc
  defp maybe_cons(list, acc) when is_list(list), do: Enum.reverse(list) ++ acc
  defp maybe_cons(item, acc), do: [item | acc]
end
