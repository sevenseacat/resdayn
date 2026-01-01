defmodule Resdayn.Importer.Quests.ScriptParser do
  def extract_journal_commands(content) when is_binary(content) do
    content
    |> parse_input()
    |> parse_lines()
    |> finalize_current_block()
    |> Map.get(:journal_commands)
  end

  # ============================================================================
  # Stack-Based Line Parser
  # ============================================================================

  defp parse_lines(lines) do
    initial = %{
      local_vars: [],
      condition_stack: [],
      # Stack of {block_effects, block_journals} for each nesting level
      block_stack: [],
      # Current block's effects and journals
      current_block_effects: [],
      current_block_journals: [],
      # Final output
      journal_commands: []
    }

    Enum.reduce(lines, initial, &parse_line/2)
  end

  defp parse_line(line, state) do
    cond do
      # New local variable
      String.starts_with?(line, "short") || String.starts_with?(line, "float") ->
        [_, name] = Regex.split(~r/\s+/, line)
        Map.update!(state, :local_vars, &[name | &1])

      # Start of a new block
      String.starts_with?(line, "if") and String.contains?(line, "(") ->
        case parse_condition(line, state.local_vars) do
          nil -> state
          condition -> push_block(state, condition)
        end

      # End of a block
      String.starts_with?(line, "elseif") ->
        case parse_condition(line) do
          nil -> pop_condition(state)
          condition -> state |> pop_condition() |> push_condition(condition)
        end

      # End of a block
      String.starts_with?(line, "endif") ->
        state
        |> finalize_current_block()
        |> pop_block()

      # Journal command - the bit we care about most
      String.starts_with?(line, "journal") ->
        handle_journal_command(state, line)

      # Effect commands
      true ->
        case parse_effects(line) do
          [] -> state
          effects -> add_block_effects(state, effects)
        end
    end
  end

  defp handle_journal_command(state, line) do
    case parse_journal_command(line) do
      nil ->
        raise "Expected to get a journal command in line '#{inspect(line)}' but did not??"

      {quest_id, index} ->
        journal = %{
          quest_id: quest_id,
          index: index,
          conditions: state.condition_stack
        }

        %{state | current_block_journals: state.current_block_journals ++ [journal]}
    end
  end

  defp add_block_effects(state, effects) do
    %{state | current_block_effects: state.current_block_effects ++ effects}
  end

  # Attach all block effects to all block journals and move to final output
  defp finalize_current_block(state) do
    if state.current_block_journals == [] do
      %{state | current_block_effects: []}
    else
      # Attach effects to all journals in this block
      finalized_journals =
        Enum.map(state.current_block_journals, fn journal ->
          Map.put(journal, :effects, state.current_block_effects)
        end)

      %{
        state
        | journal_commands: state.journal_commands ++ finalized_journals,
          current_block_effects: [],
          current_block_journals: []
      }
    end
  end

  defp push_block(state, condition) do
    %{
      state
      | condition_stack: state.condition_stack ++ [condition],
        block_stack:
          state.block_stack ++ [{state.current_block_effects, state.current_block_journals}],
        current_block_effects: state.current_block_effects,
        current_block_journals: []
    }
  end

  defp pop_block(%{block_stack: stack} = state) do
    case List.last(stack) do
      # Accounting for the *66* buggy scripts in the Morrowind game data
      # that have extra endif statements... what the hell?
      nil ->
        state

      {prev_effects, prev_journals} ->
        %{
          state
          | condition_stack: Enum.drop(state.condition_stack, -1),
            block_stack: Enum.drop(stack, -1),
            current_block_effects: prev_effects,
            current_block_journals: prev_journals
        }
    end
  end

  defp pop_condition(%{condition_stack: []} = state), do: state

  defp pop_condition(%{condition_stack: stack} = state) do
    %{state | condition_stack: Enum.drop(stack, -1)}
  end

  defp push_condition(state, condition) do
    %{state | condition_stack: state.condition_stack ++ [condition]}
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
    # Strip the outer conditional parts
    case Regex.split(~r/[\(|\)]/, line, parts: 3) do
      [_, line, _] -> do_parse_condition(String.trim(line), locals)
      [_] -> nil
    end
  end

  defp do_parse_condition(line, locals) do
    {subject, line} = parse_subject(line)

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
        parse_comparison(line, subject, :attacked)

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
        parse_comparison(line, subject, :on_pc_hit_me)

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
        # Might be a local or a global var
        result = parse_comparison(line, subject, :local_var)

        if result.target in locals do
          result
        else
          case Resdayn.Codex.Mechanics.get_game_setting_by_id(result.target) do
            {:ok, _global} -> %{result | type: :global_var}
            _ -> nil
          end
        end
    end
  end

  defp parse_comparison(line, subject, key) do
    case Regex.run(~r/^\s*["']?([^"']+)["']?\s+([<>=!]+)\s*(-?\d+|\w+)/i, line) ||
           Regex.run(~r/^\s*["']?([^"']+)["']?/i, line) do
      [_, target, op, value] ->
        value =
          case Integer.parse(value) do
            {num, ""} -> num
            :error -> value
          end

        %{
          subject: normalize_subject(subject),
          type: key,
          target: target,
          operator: parse_operator(op),
          value: value
        }

      # Implicit "is true, == 1"
      [_, target] ->
        %{
          subject: normalize_subject(subject),
          type: key,
          target: target,
          operator: :==,
          value: 1
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
          type: key,
          operator: parse_operator(operator),
          value: value
        }

      nil ->
        %{
          subject: normalize_subject(subject),
          type: key,
          operator: :==,
          value: 1
        }
    end
  end

  # ============================================================================
  # Effect Parsing
  # ============================================================================

  def parse_effects(line) do
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
  end

  defp maybe_add_effect(effects, nil), do: effects
  defp maybe_add_effect(effects, effect), do: effects ++ [effect]

  defp parse_inventory_change(line, check, key) do
    if String.contains?(line, check) do
      {subject, rest} = parse_subject(line)
      {item, count} = parse_item_and_count(rest, check)
      %{count: count, type: key, subject: normalize_subject(subject), item_id: item}
    else
      nil
    end
  end

  defp parse_mod_fac_rep(line) do
    case Regex.run(~r/modpcfacrep\s+([+-]?\d+)\s+["']?([^"'\n]+)["']?/i, line) do
      [_, amount, faction] ->
        %{
          type: :mod_faction_reputation,
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
    case Regex.run(~r/addtopic\s+["']?([^"'\n]+)["']?/i, line) do
      [_, topic] -> %{type: :add_topic, topic_id: String.trim(topic)}
      nil -> nil
    end
  end

  defp parse_goodbye("goodbye"), do: %{type: :goodbye}
  defp parse_goodbye(_), do: nil

  defp parse_command_with_number(line, check, key) do
    {subject, rest} = parse_subject(line)

    case Regex.run(~r/#{check}\s+([+-]?\s?\d+)/i, rest) do
      [_, value] ->
        value = String.replace(value, " ", "")
        %{subject: normalize_subject(subject), type: key, value: String.to_integer(value)}

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
        type: key,
        value: normalize_value(value)
      }
    else
      nil
    end
  end

  defp parse_command(line, check, key) do
    {subject, rest} = parse_subject(line)

    if rest == check do
      %{subject: normalize_subject(subject), type: key}
    else
      nil
    end
  end

  defp parse_start_script(line) do
    case Regex.run(~r/startscript\s+["']?([^"'\s\n]+)["']?/i, line) do
      [_, script_id] -> %{type: :start_script, script_id: normalize_value(script_id)}
      nil -> nil
    end
  end

  defp parse_stop_script(line) do
    case Regex.run(~r/stopscript\s+["']?([^"'\s\n]+)["']?/i, line) do
      [_, script_id] -> %{type: :stop_script, script_id: normalize_value(script_id)}
      nil -> nil
    end
  end

  defp parse_ai_follow(line) do
    {subject, line} = parse_subject(line)

    case Regex.run(~r/aifollow ["']([^"']+)["']/i, line) ||
           Regex.run(~r/aifollow ([^"'\s]+)/i, line) do
      [_, target] ->
        %{
          type: :ai_follow,
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
          type: :ai_travel,
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
          type: :ai_wander,
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
          type: :ai_escort,
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

    case Regex.run(~r/placeatpc ["']([^"']+)["']/i, line) ||
           Regex.run(~r/placeatpc ([^"'\s]+)/i, line) do
      [_, value] ->
        %{
          type: :place_at_pc,
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
          type: :position_cell,
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
end
