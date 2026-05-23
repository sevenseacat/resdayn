defmodule Resdayn.QuestAnalyzer.ScriptParser do
  @moduledoc """
  Parse raw script content into its AST form, ready for analysis.
  """

  defmodule AST do
    @moduledoc """
    An AST definition for a parsed in-game script.
    This can be used for both standalone scripts, and dialogue response scripts.
    """

    # For dialogue scripts, name and locals will be nil
    defstruct [:name, :locals, :body]
  end

  defmodule IfBlock do
    defstruct [:condition, :body, :else_clause]
  end

  defmodule WhileBlock do
    defstruct [:condition, :body]
  end

  defmodule Journal do
    defstruct [:quest_id, :index]
  end

  defmodule Effect do
    defstruct [:function, :data]
  end

  defmodule Condition do
    defstruct [:function, :data]
  end

  def parse(content) when is_binary(content) do
    lines = parse_input(content)
    {name, lines} = parse_begin(lines)
    {locals, body_lines} = extract_locals(lines)

    %AST{
      name: name,
      locals: locals,
      body: parse_body(body_lines, locals)
    }
  end

  # Pull the `begin Name` line off the top, if present. Returns
  # {name_or_nil, remaining_lines}.
  defp parse_begin(["begin " <> name | rest]), do: {name, rest}
  defp parse_begin(lines), do: {nil, lines}

  # Sweep the entire body for `short`/`long`/`float` declarations, returning
  # the locals (in declaration order) and the body with those lines removed.
  # Morrowind treats a local declaration as script-scoped regardless of
  # where it appears, so a mid-body `short laterDecl` is just as valid as
  # one at the top.
  defp extract_locals(lines) do
    Enum.reduce(lines, {[], []}, fn line, {locals, remaining} ->
      case Regex.run(~r/^(?:short|long|float)\s+(\w+)/, line) do
        [_, name] -> {locals ++ [name], remaining}
        _ -> {locals, remaining ++ [line]}
      end
    end)
  end

  # ============================================================================
  # Line Parser
  # ============================================================================

  defp parse_body(lines, locals) do
    parse_body(lines, locals, [])
  end

  defp parse_body([], _locals, acc), do: Enum.reverse(acc)

  defp parse_body([line | lines], locals, acc) do
    cond do
      # Stray block-terminator tokens at the top level — silently skip.
      # These leak when scripts have unbalanced if/while structures.
      # Without this skip, they'd fall through to `parse_single_line` and
      # become `%Effect{function: :unknown}` entries that mislead analysis.
      String.starts_with?(line, "endif") or
        String.starts_with?(line, "endwhile") or
          String.starts_with?(line, "else") ->
        parse_body(lines, locals, acc)

      String.starts_with?(line, "if") ->
        {block, rest} = parse_if_block(line, lines, locals)
        parse_body(rest, locals, [block | acc])

      String.starts_with?(line, "while") ->
        {block, rest} = parse_while_block(line, lines, locals)
        parse_body(rest, locals, [block | acc])

      true ->
        item = parse_single_line(line)
        parse_body(lines, locals, maybe_cons(item, acc))
    end
  end

  defp parse_if_block(line, lines, locals) do
    condition = parse_condition(line, locals)
    {body, else_clause, rest} = parse_block_body(lines, locals, [])

    block = %IfBlock{
      condition: condition,
      body: body,
      else_clause: else_clause
    }

    {block, rest}
  end

  defp parse_while_block(line, lines, locals) do
    condition = parse_condition(line, locals)
    {body, rest} = parse_while_body(lines, locals, [])

    block = %WhileBlock{
      condition: condition,
      body: body
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

      String.starts_with?(line, "while") ->
        {block, rest} = parse_while_block(line, lines, locals)
        parse_block_body(rest, locals, [block | acc])

      true ->
        # No keywords - a journal, effect, etc.
        item = parse_single_line(line)
        parse_block_body(lines, locals, maybe_cons(item, acc))
    end
  end

  defp parse_while_body([], _locals, acc) do
    # Unbalanced - return what we have
    {Enum.reverse(acc), []}
  end

  defp parse_while_body([line | lines], locals, acc) do
    cond do
      String.starts_with?(line, "endwhile") ->
        {Enum.reverse(acc), lines}

      String.starts_with?(line, "if") ->
        {block, rest} = parse_if_block(line, lines, locals)
        parse_while_body(rest, locals, [block | acc])

      String.starts_with?(line, "while") ->
        {block, rest} = parse_while_block(line, lines, locals)
        parse_while_body(rest, locals, [block | acc])

      true ->
        item = parse_single_line(line)
        parse_while_body(lines, locals, maybe_cons(item, acc))
    end
  end

  defp parse_single_line(line) do
    cond do
      String.starts_with?(line, "journal ") or String.starts_with?(line, "journal,") ->
        {quest_id, index} = parse_journal_command(line)
        %Journal{quest_id: quest_id, index: index}

      String.contains?(line, "->journal ") ->
        [_, rest] = String.split(line, "->", parts: 2)
        {quest_id, index} = parse_journal_command(rest)
        %Journal{quest_id: quest_id, index: index}

      line in ~w(end return) or String.starts_with?(line, "end ") ->
        nil

      true ->
        case parse_effect(line) do
          nil ->
            # Record unknown commands as generic effects
            %Effect{function: :unknown, data: %{content: line}}

          effect ->
            %Effect{function: effect.function, data: Map.drop(effect, [:function])}
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
  # Both passes use the same `all_effects` set: journals — whether at this
  # level or nested deeper — see every sibling effect from this scope plus
  # everything inherited from ancestor scopes, regardless of textual position.
  # Tracked in Linear 7CC-89; see test/resdayn/quest_analyzer/script_parser_test.exs
  # for the cases that failed under the previous "effects-before-block-only"
  # rule.
  defp walk_body(nodes, state) do
    # Pass 1: Collect all effects at this level
    {level_effects, state} = collect_effects(nodes, state)

    # All effects for journals at this level (and any nested journals reached
    # via if/while blocks below) = inherited + this level's
    all_effects = state.inherited_effects ++ level_effects

    # Pass 2: Process journals and recurse into nested blocks
    Enum.reduce(nodes, state, fn node, s ->
      case node do
        %Journal{} = journal ->
          entry = %{
            quest_id: journal.quest_id,
            index: journal.index,
            conditions: s.conditions,
            effects: all_effects
          }

          %{s | journals: s.journals ++ [entry]}

        %IfBlock{} = block ->
          walk_if_block(block, %{s | inherited_effects: all_effects})

        %WhileBlock{} = block ->
          walk_while_block(block, %{s | inherited_effects: all_effects})

        _ ->
          s
      end
    end)
  end

  # Collect all effects at this level, following StartScript if enabled
  defp collect_effects(nodes, state) do
    Enum.reduce(nodes, {[], state}, fn node, {effects, s} ->
      case node do
        %Effect{} = effect ->
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

  defp walk_if_block(%IfBlock{} = block, state) do
    # Process the "if" branch
    state = process_branch(block.condition, block.body, state)

    # Process else clause if present
    case block.else_clause do
      nil ->
        state

      %IfBlock{} = elseif_block ->
        walk_if_block(elseif_block, state)

      else_body when is_list(else_body) ->
        process_branch(nil, else_body, state)
    end
  end

  defp walk_while_block(%WhileBlock{} = block, state) do
    # Journals inside the loop body inherit the loop's guard condition,
    # the same way an if-block's body inherits its condition.
    process_branch(block.condition, block.body, state)
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
        %Effect{} = effect ->
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

  # Quest ID may be quoted or not, and may use comma separators
  def parse_journal_command(<<"journal, "::binary, line::binary>>) do
    do_parse_journal_command(line)
  end

  def parse_journal_command(<<"journal "::binary, line::binary>>) do
    do_parse_journal_command(line)
  end

  def parse_journal_command(_), do: nil

  defp do_parse_journal_command(line) do
    line = line |> String.replace("\"", "") |> String.replace(",", "")
    words = String.split(line, " ", trim: true)
    {index, quest_id} = List.pop_at(words, -1)
    {Enum.join(quest_id, " "), String.to_integer(index)}
  end

  # ============================================================================
  # Condition Parsing
  # ============================================================================
  #
  # A parsed condition has the shape:
  #
  #   %{
  #     left:     %{function: atom, subject?: term, arg?: term}
  #            |  %{local_var: name_or_arithmetic_string},
  #     operator: atom,
  #     right:    %{value: integer}
  #            |  %{local_var: name}
  #            |  %{function: atom, subject?: term, arg?: term}
  #   }
  #
  # Both sides of the comparison are expressions parsed independently, so
  # compound conditions like `player->getshortblade > player->getbluntweapon`
  # work — both sides see the same expression parser.
  #
  # Boolean-ish conditions (`getinterior`, `iswerewolf`) materialise an
  # implicit `== 1` rather than leaving operator/right blank.
  #
  # The arrow rule: a function takes a `subject` field iff a script can write
  # `subject->func` in real source. Otherwise the function is global and the
  # parsed shape omits `subject`. The atom `:rank` (was `:pc_rank`) defaults
  # to `:player` since the player is the only meaningful subject.
  # ============================================================================

  # Table of recognised script-condition functions.
  #
  #   {keyword, function_atom, arg_kind, subject_kind}
  #
  # arg_kind:
  #   :no_arg       — function takes no argument (e.g. getlevel)
  #   :string_arg   — function takes a quoted/unquoted identifier (e.g. getitemcount "x")
  #   :integer_arg  — function takes an integer literal (e.g. random 100)
  #
  # subject_kind:
  #   :actor_bound  — defaults to :self if no `subject->` prefix
  #   :global       — never carries a subject
  #   :player       — defaults to :player (rank only, for now)
  #
  # Order matters when one keyword is a prefix of another — list longest
  # first. `starts_with_keyword?/2` also enforces a word boundary after the
  # keyword so `getlevel` doesn't accidentally match `getleveltracked`.
  @function_keywords [
    # Quest / journal
    {"getjournalindex", :journal_index, :string_arg, :global},
    {"getdeadcount", :dead_count, :string_arg, :global},

    # Cell / location
    {"getpccell", :current_cell, :string_arg, :global},
    {"getinterior", :interior, :no_arg, :actor_bound},

    # Items / inventory
    {"hasitemequipped", :has_item_equipped, :string_arg, :actor_bound},
    {"getitemcount", :item_count, :string_arg, :actor_bound},
    {"hassoulgem", :has_soul_gem, :string_arg, :actor_bound},

    # Events
    {"onactivate", :on_activate, :no_arg, :actor_bound},
    {"onknockout", :on_knockout, :no_arg, :actor_bound},
    {"onpchitme", :on_hit_me, :no_arg, :actor_bound},
    {"onpcequip", :on_equip, :no_arg, :actor_bound},
    {"onmurder", :on_murder, :no_arg, :actor_bound},
    {"ondeath", :on_death, :no_arg, :actor_bound},

    # State checks
    {"getdisabled", :disabled, :no_arg, :actor_bound},
    {"getlocked", :locked, :no_arg, :actor_bound},
    {"getattacked", :attacked, :no_arg, :actor_bound},
    {"iswerewolf", :is_werewolf, :no_arg, :actor_bound},
    {"cellchanged", :cell_changed, :no_arg, :actor_bound},
    {"getweapondrawn", :weapon_drawn, :no_arg, :actor_bound},

    # Stats
    {"gethealth", :health, :no_arg, :actor_bound},
    {"getfatigue", :fatigue, :no_arg, :actor_bound},
    {"getmagicka", :magicka, :no_arg, :actor_bound},
    {"getpcrank", :rank, :string_arg, :player},
    {"getrace", :race, :string_arg, :actor_bound},

    # Spells / effects / diseases
    {"getblightdisease", :blight_disease, :no_arg, :actor_bound},
    {"getcommondisease", :common_disease, :no_arg, :actor_bound},
    {"geteffect", :effect, :string_arg, :actor_bound},
    {"getspell", :knows_spell, :string_arg, :actor_bound},

    # AI
    {"getcurrentaipackage", :current_ai_package, :no_arg, :actor_bound},
    {"getaipackagedone", :ai_package_done, :no_arg, :actor_bound},
    {"saydone", :say_done, :no_arg, :actor_bound},

    # Positioning / sight
    {"getcollidingactor", :colliding_actor, :no_arg, :actor_bound},
    {"getcollidingpc", :colliding_pc, :no_arg, :actor_bound},
    {"getstandingactor", :standing_actor, :no_arg, :actor_bound},
    {"getstandingpc", :standing_pc, :no_arg, :actor_bound},
    {"getdetected", :detected, :string_arg, :actor_bound},
    {"getdistance", :distance, :string_arg, :actor_bound},
    {"getlos", :line_of_sight, :string_arg, :actor_bound},
    {"getpos", :position, :string_arg, :actor_bound},
    {"gettarget", :target, :string_arg, :actor_bound},

    # Social
    {"getdisposition", :disposition, :no_arg, :actor_bound},
    {"scriptrunning", :script_running, :string_arg, :global},
    {"pcexpelled", :expelled, :string_arg, :global},

    # World state
    {"getbuttonpressed", :button_pressed, :no_arg, :global},
    {"getcurrentweather", :current_weather, :no_arg, :global},
    {"getsoundplaying", :sound_playing, :string_arg, :global},
    {"getwaterlevel", :water_level, :no_arg, :global},
    {"getwerewolfkills", :werewolf_kills, :no_arg, :global},
    {"dayspassed", :days_passed, :no_arg, :global},
    {"gamehour", :game_hour, :no_arg, :global},
    {"menumode", :menu_mode, :no_arg, :global},

    # Weapon skills (compound conditions / Tamriel Rebuilt runestones)
    {"getshortblade", :short_blade, :no_arg, :actor_bound},
    {"getbluntweapon", :blunt_weapon, :no_arg, :actor_bound},
    {"getlongblade", :long_blade, :no_arg, :actor_bound},
    {"getaxe", :axe, :no_arg, :actor_bound},

    # Skill: level needs to come AFTER getlevel-prefixed alternatives if any
    {"getlevel", :level, :no_arg, :actor_bound},

    # Random
    {"random", :random, :integer_arg, :global}
  ]

  def parse_condition(line, locals \\ []) do
    line = Regex.replace(~r/(if|elseif|while|\(|\))/i, line, "")

    Regex.replace(~r/\s+/, line, " ")
    |> String.trim()
    |> do_parse_condition(locals)
  end

  defp do_parse_condition("", _locals), do: nil

  defp do_parse_condition(line, locals) do
    case split_on_operator(line) do
      nil ->
        # No operator at all. Only function calls (with implicit "== 1") count
        # as conditions — a bare local-var reference or random text isn't a
        # condition, it's a non-condition line we should pass through as nil.
        case parse_expression(line, locals) do
          %{function: _} = expr -> %{left: expr, operator: :==, right: %{value: 1}}
          _ -> nil
        end

      {left_str, op, right_str} ->
        left = parse_expression(left_str, locals)
        right = parse_expression(right_str, locals)

        if is_nil(left) or is_nil(right) do
          %{function: :unknown, content: line}
        else
          %{left: left, operator: op, right: right}
        end
    end
  end

  # Find the first comparison operator in the line and split around it.
  # Operators ordered longest-first so `<=` doesn't get truncated to `<`.
  # The `<==` typo (plantScript) maps to `:<=` via `parse_operator/1`.
  #
  # The `(?<!-)` negative lookbehind keeps the `>` inside `->` from being
  # matched as a comparison operator. Without it, `player->getlevel >= 30`
  # would split as left="player-", op=">", right="getlevel >= 30".
  defp split_on_operator(line) do
    case Regex.run(~r/^(.+?)\s*(?<!-)(<==|<=|>=|==|!=|<|>|=)\s*(.+)$/, line) do
      [_, left, op_str, right] ->
        {String.trim(left), parse_operator(op_str), String.trim(right)}

      nil ->
        nil
    end
  end

  # An expression is one of: integer literal, function call, or local-var
  # reference (which may include arithmetic on locals). We try them in order
  # and stop at the first match.
  defp parse_expression(str, _locals) do
    str = str |> String.trim() |> strip_outer_parens()

    cond do
      str == "" ->
        nil

      Regex.match?(~r/^-?\d+$/, str) ->
        %{value: String.to_integer(str)}

      fc = parse_function_call(str) ->
        fc

      # Accept a single identifier or an arithmetic expression alternating
      # operand/operator. Things like "Journal Quest 50" (two consecutive
      # identifiers with no operator between) are rejected — they're script
      # commands, not conditions.
      looks_like_local_var_or_arithmetic?(str) ->
        %{local_var: str}

      true ->
        nil
    end
  end

  # An "operand" is an identifier (`^[a-zA-Z_]\w*$`) or an integer literal.
  # A valid local-var expression is either:
  #   - a single operand
  #   - operand op operand op operand … (alternating; odd token count)
  # where op is one of +, -, *, /.
  defp looks_like_local_var_or_arithmetic?(str) do
    tokens = String.split(str, ~r/\s+/, trim: true)

    cond do
      tokens == [] -> false
      rem(length(tokens), 2) == 0 -> false
      true -> Enum.all?(Enum.with_index(tokens), &valid_arith_token?/1)
    end
  end

  defp valid_arith_token?({token, idx}) do
    if rem(idx, 2) == 0 do
      Regex.match?(~r/^[a-zA-Z_]\w*$/, token) or Regex.match?(~r/^-?\d+$/, token)
    else
      token in ["+", "-", "*", "/"]
    end
  end

  defp strip_outer_parens(str) do
    case Regex.run(~r/^\(\s*(.+?)\s*\)$/, str) do
      [_, inner] -> strip_outer_parens(String.trim(inner))
      nil -> str
    end
  end

  defp parse_function_call(str) do
    {subject, rest} =
      case String.split(str, "->", parts: 2) do
        [s, r] -> {normalize_subject(String.trim(s)), String.trim(r)}
        [r] -> {nil, String.trim(r)}
      end

    case match_function_keyword(rest) do
      nil ->
        nil

      {function, arg} ->
        base = %{function: function}
        base = put_subject(base, function, subject)
        if arg != nil, do: Map.put(base, :arg, arg), else: base
    end
  end

  defp match_function_keyword(rest) do
    Enum.find_value(@function_keywords, fn {keyword, function, arg_kind, _subject_kind} ->
      if starts_with_keyword?(rest, keyword) do
        after_kw = rest |> String.replace_prefix(keyword, "") |> String.trim()

        case parse_arg(after_kw, arg_kind) do
          :no_match -> nil
          arg -> {function, arg}
        end
      end
    end)
  end

  # Word-boundary check: the char immediately after the keyword must not be
  # another word char (letter/digit/underscore). Otherwise `getlevel` would
  # match a hypothetical `getleveltracked`.
  defp starts_with_keyword?(str, keyword) do
    kw_len = String.length(keyword)

    String.starts_with?(str, keyword) and
      (String.length(str) == kw_len or
         not Regex.match?(~r/[a-zA-Z0-9_]/, String.at(str, kw_len)))
  end

  defp parse_arg("", :no_arg), do: nil
  defp parse_arg(_, :no_arg), do: :no_match

  defp parse_arg("", :string_arg), do: :no_match
  defp parse_arg(str, :string_arg), do: normalize_value(str)

  defp parse_arg("", :integer_arg), do: :no_match

  defp parse_arg(str, :integer_arg) do
    case Integer.parse(String.trim(str)) do
      {n, ""} -> n
      _ -> :no_match
    end
  end

  # Decide what to do with the subject slot:
  #   - explicit (`subject->` was present): always use it
  #   - implicit (no arrow): default based on the function's subject_kind
  defp put_subject(base, function, nil) do
    case function_subject_kind(function) do
      :actor_bound -> Map.put(base, :subject, :self)
      :player -> Map.put(base, :subject, :player)
      :global -> base
    end
  end

  defp put_subject(base, _function, subject), do: Map.put(base, :subject, subject)

  defp function_subject_kind(function) do
    Enum.find_value(@function_keywords, fn {_kw, fn_atom, _ak, sk} ->
      if fn_atom == function, do: sk
    end) || :actor_bound
  end

  # ============================================================================
  # Effect Parsing
  # ============================================================================

  # Uses || for short-circuit evaluation - stops at first match
  def parse_effect(line) do
    parse_inventory_change(line, "additem", :add_item) ||
      parse_inventory_change(line, "removeitem", :remove_item) ||
      parse_inventory_change(line, "drop", :drop_item) ||
      parse_mod_fac_rep(line) ||
      parse_command_with_string(line, "pcraiserank", :raise_rank, "player") ||
      parse_command_with_string(line, "raiserank", :raise_rank) ||
      parse_command_with_string(line, "pcjoinfaction", :join_faction, "player") ||
      parse_command_with_number(line, "modreputation", :mod_reputation) ||
      parse_command_with_number(line, "moddisposition", :mod_disposition) ||
      parse_command_with_number(line, "setdisposition", :set_disposition) ||
      parse_add_topic(line) ||
      parse_command(line, "enable", :enable) ||
      parse_command(line, "disable", :disable) ||
      parse_command(line, "activate", :activate) ||
      parse_command(line, "clearforcesneak", :clear_force_sneak) ||
      parse_wake_up_pc(line) ||
      parse_play_sound(line) ||
      parse_cast(line) ||
      parse_place_item(line) ||
      parse_command_with_string(line, "addspell", :add_spell) ||
      parse_command_with_string(line, "removespell", :remove_spell) ||
      parse_command(line, "forcegreeting", :force_greeting) ||
      parse_goodbye(line) ||
      parse_command_with_number(line, "setfight", :set_fight) ||
      parse_command_with_number(line, "setflee", :set_flee) ||
      parse_command_with_number(line, "setalarm", :set_alarm) ||
      parse_command_with_number(line, "sethello", :set_hello) ||
      parse_start_script(line) ||
      parse_stop_script(line) ||
      parse_command_with_string(line, "startcombat", :start_combat) ||
      parse_stop_combat(line) ||
      parse_ai_follow(line) ||
      parse_ai_travel(line) ||
      parse_ai_wander(line) ||
      parse_ai_escort(line) ||
      parse_command_with_number(line, "lock", :lock) ||
      parse_command(line, "unlock", :unlock) ||
      parse_place_at_pc(line) ||
      parse_position_cell(line) ||
      parse_command_with_number(line, "modstrength", :mod_strength) ||
      parse_command_with_number(line, "modintelligence", :mod_intelligence) ||
      parse_command_with_number(line, "modwillpower", :mod_willpower) ||
      parse_command_with_number(line, "modendurance", :mod_endurance) ||
      parse_command_with_number(line, "modspeed", :mod_speed) ||
      parse_command_with_number(line, "modagility", :mod_agility) ||
      parse_command_with_number(line, "modluck", :mod_luck) ||
      parse_command_with_number(line, "modpersonality", :mod_personality) ||
      parse_command_with_number(line, "modfight", :mod_fight) ||
      parse_command_with_number(line, "modflee", :mod_flee) ||
      parse_show_map(line) ||
      parse_set_variable(line) ||
      parse_mod_faction_reaction(line) ||
      parse_set_crime_level(line) ||
      parse_clear_expelled(line) ||
      parse_expell(line) ||
      parse_message_box(line) ||
      parse_ai_follow_cell(line) ||
      parse_choice(line)
  end

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
    # Handle both space and comma separated: "modpcfacrep 10 faction" or "modpcfacrep, 10, faction"
    case Regex.run(~r/modpcfacrep[,\s]+([+-]?\d+)[,\s]+["]?([^"\n,]+)["]?/i, line) do
      [_, amount, faction] ->
        %{
          function: :mod_faction_reputation,
          faction_id: String.trim(faction),
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

    case Regex.run(~r/#{check}[,\s]+([+-]?\s?\d+)/i, rest) do
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

  defp parse_stop_combat(line) do
    {subject, rest} = parse_subject(line)

    case Regex.run(~r/^stopcombat\s*(.*)$/i, rest) do
      [_, ""] ->
        %{function: :stop_combat, subject: normalize_subject(subject)}

      [_, target] ->
        %{
          function: :stop_combat,
          subject: normalize_subject(subject),
          target: normalize_subject(target)
        }

      nil ->
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

    case Regex.run(~r/aiwander[,\s]+(\d+)/i, line) do
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

    case Regex.run(~r/placeatpc[,\s]+["]([^"]+)["]/i, line) ||
           Regex.run(~r/placeatpc[,\s]+([^"\s,]+)/i, line) do
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

  # Global command — no subject. `wakeuppc` takes no args.
  defp parse_wake_up_pc(line) do
    if String.trim(line) == "wakeuppc", do: %{function: :wake_up_pc}
  end

  # Global command — no subject. Takes one quoted/unquoted sound id which
  # may contain spaces when quoted (e.g. "bm pipe medium").
  defp parse_play_sound(line) do
    case Regex.run(~r/^\s*playsound\s+"?([^"\n]+?)"?\s*$/i, line) do
      [_, sound_id] -> %{function: :play_sound, sound_id: String.trim(sound_id)}
      _ -> nil
    end
  end

  # Cast spell at target. Subject (the caster) defaults to :self when no
  # `subject->cast` prefix is present.
  defp parse_cast(line) do
    {subject, rest} = parse_subject(line)

    case Regex.run(~r/^\s*cast\s+(?:"([^"]+)"|(\S+))\s+(\S+)/i, rest) do
      [_, quoted_spell, "", target] ->
        %{
          function: :cast,
          subject: normalize_subject(subject),
          spell_id: quoted_spell,
          target: normalize_subject(target)
        }

      [_, "", unquoted_spell, target] ->
        %{
          function: :cast,
          subject: normalize_subject(subject),
          spell_id: unquoted_spell,
          target: normalize_subject(target)
        }

      _ ->
        nil
    end
  end

  # Global command — no subject. `placeitem item_id x y z rotation` where
  # each coord can be a literal integer or a local-variable name.
  defp parse_place_item(line) do
    case Regex.run(
           ~r/^\s*placeitem\s+(?:"([^"]+)"|(\S+))\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/i,
           line
         ) do
      [_, "", unquoted_item, x, y, z, rot] ->
        place_item_map(unquoted_item, x, y, z, rot)

      [_, quoted_item, _, x, y, z, rot] ->
        place_item_map(quoted_item, x, y, z, rot)

      _ ->
        nil
    end
  end

  defp place_item_map(item_id, x, y, z, rot) do
    %{
      function: :place_item,
      item_id: item_id,
      x: parse_int_or_local(x),
      y: parse_int_or_local(y),
      z: parse_int_or_local(z),
      rotation: parse_int_or_local(rot)
    }
  end

  defp parse_int_or_local(str) do
    case Integer.parse(str) do
      {n, ""} -> n
      _ -> str
    end
  end

  defp parse_ai_follow_cell(line) do
    {subject, line} = parse_subject(line)

    case Regex.run(~r/aifollowcell[,\s]+(\w+)[,\s]+["]([^"]+)["]/i, line) ||
           Regex.run(~r/aifollowcell[,\s]+["]([^"]+)["]/i, line) do
      [_, target, cell] ->
        %{
          function: :ai_follow_cell,
          subject: normalize_subject(subject),
          target: normalize_subject(target),
          cell: cell
        }

      [_, cell] ->
        %{
          function: :ai_follow_cell,
          subject: normalize_subject(subject),
          target: :player,
          cell: cell
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

  defp parse_show_map(line) do
    case Regex.run(~r/^showmap\s+["]?([^"\n]+)["]?/i, line) do
      [_, location] ->
        %{function: :show_map, location: String.trim(location)}

      nil ->
        nil
    end
  end

  defp parse_set_variable(line) do
    # Handle quoted object property syntax: set "npc name".variable to value
    case Regex.run(~r/^set\s+"([^"]+)"\.(\w+)\s+to\s+(.+)$/i, line) do
      [_, subject, variable, value] ->
        %{
          function: :set_variable,
          subject: subject,
          variable: variable,
          value: String.trim(value)
        }

      nil ->
        # Handle unquoted object property syntax: set object.variable to value
        case Regex.run(~r/^set\s+(\w+)\.(\w+)\s+to\s+(.+)$/i, line) do
          [_, subject, variable, value] ->
            %{
              function: :set_variable,
              subject: subject,
              variable: variable,
              value: String.trim(value)
            }

          nil ->
            # Handle simple variable: set variable to value
            case Regex.run(~r/^set\s+(\w+)\s+to\s+(.+)$/i, line) do
              [_, variable, value] ->
                %{function: :set_variable, variable: variable, value: String.trim(value)}

              nil ->
                nil
            end
        end
    end
  end

  defp parse_mod_faction_reaction(line) do
    # ModFactionReaction faction1 faction2 value - faction1's reaction towards faction2
    # Try quoted factions first (may contain spaces)
    case Regex.run(~r/^modfactionreaction[,\s]+"([^"]+)"[,\s]+"([^"]+)"[,\s]+([+-]?\d+)/i, line) do
      [_, faction, towards, value] ->
        %{
          function: :mod_faction_reaction,
          faction: faction,
          towards: towards,
          value: String.to_integer(value)
        }

      nil ->
        # Try unquoted single-word factions
        case Regex.run(~r/^modfactionreaction[,\s]+(\w+)[,\s]+(\w+)[,\s]+([+-]?\d+)/i, line) do
          [_, faction, towards, value] ->
            %{
              function: :mod_faction_reaction,
              faction: faction,
              towards: towards,
              value: String.to_integer(value)
            }

          nil ->
            nil
        end
    end
  end

  defp parse_set_crime_level(line) do
    case Regex.run(~r/^setpccrimelevel\s+(\d+)/i, line) do
      [_, value] ->
        %{function: :set_crime_level, value: String.to_integer(value)}

      nil ->
        nil
    end
  end

  defp parse_clear_expelled(line) do
    case Regex.run(~r/^pcclearexpelled\s*["]?([^"\n]*)["]?/i, line) do
      [_, ""] ->
        %{function: :clear_expelled, faction: nil}

      [_, faction] ->
        %{function: :clear_expelled, faction: normalize_value(faction)}

      nil ->
        nil
    end
  end

  defp parse_expell(line) do
    case Regex.run(~r/^pcexpell\s+["]?([^"\n]+)["]?/i, line) do
      [_, faction] ->
        %{function: :expell, faction: normalize_value(faction)}

      nil ->
        nil
    end
  end

  defp parse_message_box(line) do
    case Regex.run(~r/^messagebox\s+"([^"]+)"/i, line) do
      [_, message] ->
        %{function: :message_box, message: message}

      nil ->
        nil
    end
  end

  # Parse Choice command - handles "choice", "choice:", and "choice," variants
  # Format: Choice "text1" N "text2" M ... or Choice, "text1", N, "text2", M ...
  defp parse_choice(line) do
    # Strip the "choice" prefix with optional colon or comma
    case Regex.run(~r/^choice[:,]?\s*/i, line) do
      nil ->
        nil

      [prefix] ->
        rest = String.slice(line, String.length(prefix)..-1//1)
        # Remove commas outside quotes for uniform parsing
        normalized = strip_commas_outside_quotes(rest)
        choices = extract_choices(normalized, [])
        # Return even if empty (some scripts have malformed Choice with no options)
        %{function: :choice, choices: choices}
    end
  end

  # Extract choice pairs: "text" N "text" M ...
  defp extract_choices("", acc), do: Enum.reverse(acc)

  defp extract_choices(str, acc) do
    str = String.trim(str)

    # Use non-greedy matching to find text between quotes
    # Allow optional space between closing quote and number (some scripts have typos)
    # Also accept single quote as closing (some scripts have mismatched quotes)
    case Regex.run(~r/^"(.+?)["']\s*(\d+)\s*(.*)$/s, str) do
      [_, text, num, rest] ->
        extract_choices(rest, [{text, String.to_integer(num)} | acc])

      nil ->
        # Try unquoted single-word options: choice yes 1 no 2
        case Regex.run(~r/^(\w+)\s+(\d+)\s*(.*)$/s, str) do
          [_, text, num, rest] ->
            extract_choices(rest, [{text, String.to_integer(num)} | acc])

          nil ->
            Enum.reverse(acc)
        end
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
  defp maybe_cons(item, acc), do: [item | acc]
end
