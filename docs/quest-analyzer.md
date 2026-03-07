# Quest Analyzer

The quest analyzer (`Resdayn.Importer.Quests.Analyzer`) takes the raw Morrowind game data (quests, dialogue responses, scripts, NPCs, items, cell references) and produces a structured analysis of each quest: its journal entries, how it progresses (transitions), which NPCs/items/locations are involved, and which dialogue topics are used.

## The big picture

A Morrowind quest is just an ID (like `A1_4_MuzgobInformant`) with a set of **journal entries** at numbered indices. The game advances a quest by calling `Journal "QuestID" <index>` from a script. Those scripts can live in two places:

1. **Dialogue response scripts** - inline script attached to a dialogue line
2. **Standalone NPC scripts** - a script file attached to an NPC that runs every frame

The analyzer's main job is: for each quest, find every script that calls `Journal` for it, figure out what state the quest must be in for that script to run, and collect the NPCs/items/locations involved along the way.

## Data flow

```
                    +-----------------+
                    |   Script Map    |  All game scripts, keyed by ID
                    +--------+--------+
                             |
              +--------------+--------------+
              |                             |
    +---------v----------+      +-----------v-----------+
    | Dialogue Responses |      | Standalone Scripts    |
    | (with parsed       |      | (parsed into journal  |
    |  script_content)   |      |  commands per quest)  |
    +--------+-----------+      +-----------+-----------+
             |                              |
             |  filter by quest ID          |
             +-------------+----------------+
                           |
                  +--------v--------+
                  | Per-Quest Loop  |
                  +-----------------+
                  | 1. Transitions  |  How the quest progresses
                  | 2. Key NPCs    |  Who's involved
                  | 3. Key Items   |  What items matter
                  | 4. Key Locations|  Where things happen
                  | 5. Topics      |  Dialogue topics used
                  +-----------------+
```

## Phase 1: Loading data

The analyzer front-loads everything before the per-quest loop. This avoids N+1 queries.

### Script map (`load_script_map`)
Loads all scripts into `%{downcased_script_id => script_text}`. Used by the script parser for `follow_scripts` (when a script calls `StartScript "OtherScript"`, the parser can follow the call and include effects from the other script).

### Dialogue responses (`load_dialogue_with_scripts`)
Loads all dialogue responses that have scripts, then **parses each script** using `ScriptParser.extract_journal_commands/3`. The parsed result replaces the raw `script_content` string with a map:

```
%{downcased_quest_id => [%{index: 10, effects: [...], ...}]}
```

So each response knows which quests it updates and what journal index it sets.

### Standalone script journals (`load_scripts`)
Parses every script in the game looking for journal commands. Groups them by quest ID. These represent quest advances triggered by NPC scripts rather than dialogue.

### NPCs (`load_all_npcs`)
All NPCs with their cell placements (`cell_id` and `cell_name`). Cell ID is the raw ID (like `-5,4` for exteriors or `Balmora, Guild of Mages` for interiors). Cell name is the display name from the cell record.

### Item locations (`load_item_locations`)
Two SQL queries that build an `ItemLocations` index (see below).

### Topic availability (`build_topic_availability`)
Builds a `TopicAvailability` index (see below).

### Choice chain (`ChoiceChain.build_index`)
Builds a `ChoiceChain` index (see below).

## Phase 2: Per-quest analysis

For each quest, the analyzer runs through several steps:

### Step 1: Find transitions

A **transition** represents "the quest moves to journal index N." Each has:

- `index` - the target journal index
- `from_min` / `from_max` - what journal state the quest must be in (the "precondition")
- `trigger_type` - `:dialogue_response` or `:script`
- `trigger_id` - the response ID or script ID
- `trigger_topic_id` - for dialogue triggers, which topic it's under

**From dialogue:** Filter `dialogue_with_scripts` to responses whose parsed script_content has an entry for this quest. For each journal command, extract `from_min`/`from_max` from the response's conditions (e.g., `journal "QuestID" >= 10` means `from_min: 10`).

If the response has no journal condition, try two fallback strategies:
1. **Choice chain** - if the response has a `choice == N` condition, look up the parent response that presented the choice. The parent's journal index becomes `from_min`.
2. **Topic availability** - if the dialogue topic is only available after a certain quest state, use that as `from_min`.

**From standalone scripts:** Map each script journal command to a transition with `from_max: index - 1` (the script must run *before* this index is set).

**Narrowing ranges:** After collecting all transitions, `narrow_from_ranges` cross-references them with known journal indices. If a range like `10-19` contains only one known journal index (say, `10`), the range gets pinned to `10-10`. If `from_max` is set but no journal indices exist in `0..from_max`, this is the quest start (pinned to `0-0`).

### Step 2: Collect key NPCs

NPCs come from three sources:

1. **Dialogue speakers** (`dialogue_npc_ids`) - the `speaker_npc_id` on dialogue responses that update this quest. These are NPCs you talk to during the quest.

2. **Script bearers** (`script_npc_ids`) - NPCs whose attached script updates this quest's journal. Example: an NPC has `scriptTGAldruhnMG` attached, and that script calls `Journal "TG_LootAldruhnMG" 10`.

3. **Effect targets** (`effect_npc_ids`) - NPCs referenced as subjects in script effects (enable, disable, position_cell, mod_disposition, etc.) from quest-related scripts. **Currently this is too broad** - it includes NPCs that just get a disposition bump, which doesn't make them relevant to the quest. Should probably be filtered to only meaningful effects like enable/disable/position_cell.

### Step 3: Collect key items

Items come from three sources:

1. **Condition items** - checked via `item "ItemID" >= N` in dialogue response conditions. These are items the player must have for dialogue to appear (quest items you need to obtain).

2. **Dialogue script items** - items added/removed by `additem`/`removeitem` in dialogue scripts for this quest.

3. **Standalone script items** - items added/removed by NPC scripts that update this quest.

`gold_001` is excluded because many quests check "do you have N gold?" as a condition, and gold is everywhere.

### Step 4: Collect key locations

Locations are derived (not directly specified in quest data):

1. **From NPCs** - for each key NPC, look up their cell placement. Both `cell_id` (the raw ID) and `cell_name` (the display name) are included. This means one NPC can contribute two "locations" that represent the same place.

2. **From items** - uses the `ItemLocations` module. For each **condition item** (items checked in dialogue conditions), resolve where it exists in the world through three paths:
   - Direct cell reference (item placed in a cell)
   - Inventory holder (item is inside a container/NPC, use the container's cell)
   - Script add_item target (item is added to a container/NPC by a script, use that target's cell)

   Only **uniquely-placed** references count (exactly 1 cell reference in the whole game). If an item or container appears in multiple cells, it's not specific enough to be a quest location.

### Step 5: Collect dialogue topics

Simply the `topic_id` from each dialogue response that updates this quest.

## Supporting modules

### ScriptParser

Parses raw TES3 script text into an AST, then extracts journal commands with their surrounding context (conditions from `if` blocks, effects like `additem`, `disable`, `addtopic`, etc.).

Key concept: **`extract_journal_commands`** walks the AST looking for `Journal` calls. For each one, it captures:
- The quest ID and index
- Conditions from enclosing `if` blocks
- Effects that appear at the same level or in parent blocks
- Effects from followed scripts (when `follow_scripts: true` and a `StartScript` call is encountered)

The **two-pass approach** in `walk_body`: first collect all effects at a level, then process journal entries. This ensures a journal command gets all sibling effects, not just those that appear before it in the script.

Effects have a **subject** - the entity they target. If a line is `"SomeNPC"->disable`, the subject is `"SomeNPC"`. If there's no explicit subject, it's `:self`. `Player->` becomes `:player`.

### TopicAvailability

Tracks when dialogue topics become available to the player during a quest. Topics become available in two ways:

1. **Explicitly** - via `AddTopic "TopicName"` in a dialogue script
2. **Implicitly** - when a topic name appears in the text content of a dialogue response (Morrowind automatically adds topics that are mentioned in dialogue)

The module builds an index mapping `topic_id -> [{quest_id, from_min, from_max}]`. When the analyzer can't determine `from_min` for a transition from conditions or choice chains, it checks: "is this topic only available after a certain quest state?" If so, that becomes the `from_min`.

Script-originated topic availability is added separately via `add_script_topic_availability` - when a standalone script both sets a journal index and adds a topic, we know the topic becomes available at that index.

### ChoiceChain

Links choice-handling dialogue responses to their parent responses. In Morrowind, a response can present choices:

```
Journal "MV_DeadTaxman" 20
Choice "Yes, I found 200 septims" 1 "No, nothing" 2
```

Follow-up responses handle each choice with a `choice == N` condition. These responses often have no journal condition of their own, so the analyzer can't tell what quest state they require. ChoiceChain solves this by tracking which response presented the choice and what journal index it set.

Index key: `{topic_id, speaker_npc_id, choice_number}` -> `journal_index`

### ItemLocations

Resolves cell locations from quest-critical items. Pre-built from two SQL queries:

- `unique_placements`: references with exactly 1 cell placement in the game (`%{ref_id => cell_id}`)
- `holders`: which containers/NPCs hold each item (`%{item_id => [holder_ids]}`)

Given a list of condition item IDs and optional add_item targets, resolves locations through three paths (direct placement, inventory holder, script add_item target), filtering to uniquely-placed references only.

## Known issues / future work

- **Effect targets are too broad** - any NPC referenced in any effect gets included as a key NPC. A `mod_disposition` bump doesn't make an NPC relevant to the quest. Should filter to meaningful effects (enable, disable, position_cell, ai_follow, etc.).

- **No categorization** - NPCs, items, and locations are flat lists with no indication of *why* they're included. Adding provenance (e.g., "dialogue_speaker", "effect_target", "condition_item", "from_npc:caius_cosades") would make the output much more useful.

- **Exterior cells as locations** - exterior coordinate cells like `-5,4` are valid placements but aren't meaningful quest locations the way interior cells are. May want to distinguish or de-prioritize them.

- **Duplicate locations from cell_id vs cell_name** - an NPC contributes both their `cell_id` and `cell_name`, which may represent the same physical location with different identifiers.
