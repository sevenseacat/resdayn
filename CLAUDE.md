# Claude Learning Notes

This file contains critical learnings to avoid making the same mistakes again.

## Database Migrations and Foreign Key References

### Problem: Incorrect Foreign Key Target
When implementing the Region resource, I initially assumed `disturb_sleep_creature_id` referenced individual Creature records. After generating migrations and attempting import, foreign key constraints failed.

**Learning**: Always verify what records actually reference before creating relationships:
```bash
# Check what type of records IDs actually reference
mix run -e "
records = Resdayn.Parser.read(...) |> Enum.to_list()
creature_ids = records |> filter_by_type(Creature) |> get_ids()
levelled_list_ids = records |> filter_by_type(CreatureLevelledList) |> get_ids()
# Test which set contains the referenced IDs
"
```

### Problem: Migration Regeneration Process
When I discovered the foreign key was wrong, I initially tried to generate a new migration without properly cleaning up the old one.

**Learning**: When rolling back migrations to regenerate them:
1. Roll back the migration: `mix ecto.rollback`
2. Delete the migration file: `priv/repo/migrations/TIMESTAMP_*.exs`
3. Delete the snapshot file: `priv/resource_snapshots/repo/*/TIMESTAMP.json`
4. Then regenerate with `mix ash.codegen`

## Ash Type Usage

### Problem: Using Atom Constraints Instead of Enums
I initially used `constraints: [one_of: [...]]` for the sound_type attribute instead of proper Ash.Type.Enum.

**Learning**: Always use `Ash.Type.Enum` for enumerated values instead of atom constraints:
```elixir
# Wrong
attribute :sound_type, :atom, constraints: [one_of: [:left_foot, :right_foot]]

# Right
defmodule SoundType do
  use Ash.Type.Enum, values: [:left_foot, :right_foot]
end
attribute :sound_type, SoundType
```

## Embedded Resources

### Problem: Action Definitions for Embedded Resources
Embedded resources need explicit action definitions with proper accept lists, not just `defaults [:create, :update]`.

**Learning**: For embedded resources, always define actions explicitly:
```elixir
actions do
  defaults [:read]
  
  create :create do
    primary? true
    accept [:field1, :field2]
  end
  
  update :update do
    accept [:field1, :field2]
  end
end
```

## Data Structure Investigation

### Problem: Assuming Simple Data Structures
I initially assumed the sound data from the parser was a simple array of maps, but it was actually nested arrays that needed flattening.

**Learning**: Always debug parser output before writing importers:
```elixir
# Debug what the parser actually produces
records |> filter_by_type(TargetType) |> Enum.take(3) |> inspect_data_structure()
```

### Problem: Not Checking Data Dependencies
I placed Region import before its dependencies (CreatureLevelledList), causing foreign key constraint failures.

**Learning**: Always verify import order based on foreign key dependencies. Resources that reference others must be imported after their dependencies.

## Query Syntax in Mix Run Scripts

### Problem: Forgetting to Require Ash.Query
When testing relationships in `mix run` scripts, I forgot that `Ash.Query.filter` requires `require Ash.Query`.

**Learning**: Always add `require Ash.Query` at the top of scripts that use query filters:
```elixir
mix run -e "
require Ash.Query
MyResource |> Ash.Query.filter(...) |> Ash.read!()
"
```

## Custom Types and Defaults

### Problem: Complex Default Values
Custom types with complex default values (like Weather maps) can't be converted to Ecto defaults automatically, causing migration warnings.

**Learning**: For complex custom types, expect migration warnings about defaults. The migration will set defaults to `nil` and you can edit manually if needed. Consider implementing `EctoMigrationDefault` protocol if this becomes common.

## Referencable vs Non-Referencable Resources

### Learning: Not All Resources Need Referencable Extension
Some resources (like Region) are not meant to be referenced by other game objects and should not include the Referencable extension. Only add Referencable to resources that can actually be referenced in-game.

## Embedded Resources vs Custom Types

### Problem: Using Custom Types for Complex Structured Data
I initially created a Weather custom type using `Ash.Type.NewType` with map constraints, but this caused migration warnings and was less flexible than embedded resources.

**Learning**: For complex structured data with multiple fields, prefer embedded resources over custom types:

```elixir
# Less ideal - Custom type with map constraints
defmodule Weather do
  use Ash.Type.NewType,
    subtype_of: :map,
    constraints: [
      fields: [
        clear: [type: :integer, default: 0],
        cloudy: [type: :integer, default: 0]
      ]
    ]
end

# Better - Embedded resource with explicit attributes
defmodule Weather do
  use Ash.Resource,
    data_layer: :embedded

  attributes do
    attribute :clear, :integer, allow_nil?: false, default: 0, public?: true
    attribute :cloudy, :integer, allow_nil?: false, default: 0, public?: true
  end

  actions do
    defaults [:read]
    create :create do
      primary? true
      accept [:clear, :cloudy]
    end
  end
end
```

**Benefits of embedded resources:**
- Individual attributes with proper defaults that don't cause migration warnings
- Type safety and validation at the attribute level
- Better query capabilities and relationship support
- Cleaner API when accessing nested data
- No need to implement custom casting/dumping logic

## Handling Duplicate Records in Importers

### Problem: Duplicate Cell IDs from Game Data
When importing `Sky_Main.esm`, the Cell importer failed with unique constraint violations. Investigation revealed that the file contained duplicate exterior cells at the same grid coordinates but with different regions.

**Analysis**: Using the parser to check for duplicates:
```elixir
# Check for duplicate cell IDs in Sky_Main.esm
mix run -e "
records = Resdayn.Parser.read(Path.join(['../data/', 'Sky_Main.esm'])) |> Enum.to_list()

cells = records
|> Enum.filter(fn record -> record.type == Resdayn.Parser.Record.Cell end)
|> Enum.map(fn record ->
  grid_position = if record.data.flags.interior, do: nil, else: record.data.grid_position
  id = if is_list(grid_position), do: Enum.join(grid_position, ','), else: record.data.name
  {id, record}
end)

id_groups = Enum.group_by(cells, fn {id, _} -> id end)
duplicates = Enum.filter(id_groups, fn {_id, group} -> length(group) > 1 end)
"
```

**Findings**: 
- Cell ID "-101,12": 2 cells (Midkarth Region with 173 references, Vorndgad Forest Region with 0 references)
- Cell ID "-100,12": 2 cells (Midkarth Region with 146 references, Vorndgad Forest Region with 0 references)

**Learning**: Game data can contain legitimate duplicates where the same coordinates exist in different contexts. The pattern showed that the first cell had content while later cells were empty placeholders.

**Solution**: Modified the Cell importer to keep only the first occurrence of each ID:
```elixir
# In Cell importer process/2 function
records
|> of_type(Resdayn.Parser.Record.Cell)
|> Enum.map(fn record ->
  # ... existing processing logic ...
  {id, processed_cell_data}
end)
# Handle duplicates by keeping only the first cell for each ID
|> Enum.uniq_by(fn {id, _cell_data} -> id end)
|> Enum.map(fn {_id, cell_data} -> cell_data end)
|> separate_for_import(Resdayn.Codex.World.Cell)
```

**Result**: Successfully reduced 644 cells to 642 by removing empty duplicate cells, keeping the meaningful data while preventing unique constraint violations.

## Source File Tracking and Event System Implementation

### Problem: Implementing Comprehensive Data Provenance and Audit Trails
Feature 1 required implementing source file tracking to know which data files touched each record, along with an event system to audit import activities. This involved extending the existing import system without breaking backwards compatibility.

### Key Implementation Challenges and Solutions

#### Challenge 1: JSON Serialization of Complex Ash Structs
**Problem**: When storing event changes in the database, complex Ash structs (like `Spell.Effect`) couldn't be serialized to JSON due to embedded metadata and relationships.

**Error encountered**:
```
Protocol.UndefinedError: protocol Jason.Encoder not implemented for type Resdayn.Codex.Mechanics.Spell.Effect
```

**Solution**: Implemented recursive serialization that strips Ash metadata:
```elixir
defp serialize_for_json(value) when is_struct(value) do
  value
  |> Map.from_struct()
  |> Map.drop([:__meta__])
  |> serialize_for_json()
end

defp serialize_for_json(%Ash.NotLoaded{}), do: nil
defp serialize_for_json(value) when is_list(value) do
  Enum.map(value, &serialize_for_json/1)
end
```

**Learning**: When storing change events for Ash resources, always serialize complex objects to strip framework metadata before JSON encoding.

#### Challenge 2: Event Creation Action Configuration
**Problem**: Default Ash create actions don't automatically accept all attributes, causing events to fail with "NoSuchInput" errors.

**Solution**: Define explicit create action with accept list:
```elixir
actions do
  defaults [:read]
  
  create :create do
    primary? true
    accept [:event_type, :resource_type, :resource_id, :source_file_id, :changes]
  end
end
```

**Learning**: For event/audit resources, explicitly define create actions with comprehensive accept lists rather than relying on defaults.

#### Challenge 3: Async Event Creation Performance
**Problem**: Synchronous event creation during bulk imports caused timeouts when processing large numbers of records.

**Solution**: Async event creation with error handling:
```elixir
Task.start(fn -> 
  case emit_create_event(resource, record.id, source_file_id) do
    {:ok, _event} -> :ok
    {:error, error} -> IO.puts("Error creating event: #{inspect(error)}")
  end
end)
```

**Learning**: For audit events during bulk operations, use async tasks to avoid blocking the main import process. Include error handling since failures shouldn't break imports.

#### Challenge 4: Change Detection Granularity
**Problem**: Need to distinguish between "content changes" (actual data modifications) and "metadata updates" (like adding source file IDs to previously untracked records).

**Solution**: Configurable ignore attributes with special handling for source tracking:
```elixir
# In resource definition
importable do
  ignore_attributes [:next_dialogue_id, :previous_dialogue_id]
end

# In change detection
def significant_change?(resource, existing_record, new_data) do
  ignore_attrs = Importable.ignore_attributes(resource)
  # Compare only significant attributes...
end
```

**Learning**: Provide per-resource configuration for what constitutes a "significant" change. System metadata updates shouldn't trigger the same events as content changes.

#### Challenge 5: Backwards Compatibility During Major System Changes
**Problem**: Adding source tracking to existing import system without breaking 40+ existing record importers.

**Solution**: Dual-path processing with feature detection:
```elixir
if source_file_id && has_importable_extension?(resource) do
  SourceTracker.process_with_tracking(records, resource, source_file_id, opts)
else
  # Legacy path for resources without source tracking
  existing = find_existing(resource, records)
  # ... original logic
end
```

**Learning**: When adding major features to existing systems, implement feature detection and dual processing paths to maintain backwards compatibility.

### Architecture Decisions

#### Extension-Based Feature Design
Used Spark DSL extension pattern for source tracking capabilities:
```elixir
defmodule Resdayn.Codex.Importable do
  use Spark.Dsl.Extension, 
    sections: [@importable],
    transformers: [__MODULE__.AddImportAction]
end
```

**Benefits**: Resources opt-in to source tracking, automatic action generation, clean separation of concerns.

#### Event-Driven Audit Trail
Chose AshEvents for audit trails rather than building custom logging:
- Leverages existing Ash patterns
- Built-in querying capabilities  
- Structured event data with relationships

#### Async Event Processing
Events are created asynchronously to avoid impacting import performance:
- Main import process isn't slowed by event creation
- Failed events don't break imports
- Error reporting for debugging

### Final Results
Successfully implemented comprehensive source file tracking:
- ✅ 46 events created during Tribunal.esm import test
- ✅ Source file IDs correctly tracked: `["Tribunal.esm"]`  
- ✅ Detailed change diffs with clean JSON serialization
- ✅ Zero impact on import performance (async events)
- ✅ Backwards compatibility maintained

**Testing verification**: Event for "almalexia's grace" spell showed clean before/after diff of spell effects, proving the system captures meaningful change information while properly serializing complex Ash objects.

**Learning**: Complex features like audit trails require careful attention to serialization, performance, and backwards compatibility. The combination of Spark DSL extensions, AshEvents, and async processing provides a robust foundation for data provenance tracking.

## Source File Tracking Bug: Double-Processing Resources

### Problem: Source File IDs Being Replaced Instead of Merged
During debugging of source file tracking, discovered that cell `1,-13` had its source files replaced from `["Morrowind.esm"]` to `["Tribunal.esm"]` instead of being merged to `["Morrowind.esm", "Tribunal.esm"]` when importing Tribunal.esm after Morrowind.esm.

### Root Cause Analysis
The issue stemmed from resources being processed twice during the same import:

1. **Cell importer** processes the cell first - correctly merges source file IDs
2. **CellReference importer** processes the same cell again - overwrites the merged source file IDs

**Example flow during Tribunal.esm import:**
```
1. Cell importer: ["Morrowind.esm"] + ["Tribunal.esm"] = ["Morrowind.esm", "Tribunal.esm"] ✓
2. CellReference importer: overwrites with ["Tribunal.esm"] ✗
```

### Investigation Process
Used debugging output to trace the exact flow:
```elixir
# During Tribunal.esm import:
DEBUG: Processing cell 1,-13
  Existing source IDs: ["Morrowind.esm"]
  New source file ID: "Tribunal.esm" 
  Is new source: true
DEBUG: Significant change detected for cell 1,-13  # Cell importer

DEBUG: Processing cell 1,-13
  Existing source IDs: ["Morrowind.esm", "Tribunal.esm"]  # After first processing
  New source file ID: "Tribunal.esm"
  Is new source: false  # Already in list from first processing
DEBUG: Significant change detected for cell 1,-13  # CellReference importer
```

**Key insight**: The second processing (CellReference importer) went through the "significant change" path but didn't properly preserve the merged source file IDs.

### The Bug Location
In `SourceTracker.process_with_tracking/4`, the "significant change" branch had incorrect source file ID merging logic:

```elixir
# Bug was here:
data = if is_new_source do
  Map.update!(record, :source_file_ids, &(existing_record.source_file_ids ++ &1))
else
  record  # ← This only contained ["Tribunal.esm"], losing ["Morrowind.esm"]
end
```

### The Fix
Modified the logic to always properly merge source file IDs regardless of whether it's a "new source":

```elixir
# Fixed version:
merged_source_ids = if is_new_source do
  existing_record.source_file_ids ++ record.source_file_ids
else
  # Even if not a new source, preserve existing source file IDs
  current_ids = existing_record.source_file_ids || []
  if source_file_id in current_ids do
    current_ids
  else
    current_ids ++ [source_file_id]
  end
end

data = Map.put(record, :source_file_ids, merged_source_ids)
```

### Code Quality Improvements
**Issue**: The `SourceTracker` module had grown long and repetitive with duplicated logic for event emission and source file merging.

**Solution**: Refactored into smaller, focused functions:
- `significant_attributes/1` - Extract significant attributes logic
- `merge_source_file_ids/3` - Centralize source file merging logic
- `process_create/2`, `process_significant_update/5`, `process_tracking_update/4` - Separate processing paths
- `emit_*_event_async/2,3,4` - Centralize async event emission

### Testing Strategy
Created comprehensive tests covering:
1. Basic source file ID addition and merging
2. Significant change detection (excluding source tracking fields)
3. The specific double-processing scenario that caused the bug
4. Edge cases like nil source file IDs

**Key test insight**: The `significant_change?/3` function needed to exclude `source_file_ids` and `flags` from comparison since these are internal tracking fields, not business data.

### Lessons Learned
1. **Double-processing resources**: When a resource gets processed multiple times in the same import (e.g., by different importers), ensure source file tracking logic handles this correctly.

2. **Source file merging**: Always preserve existing source file IDs when merging, never replace them unless explicitly intended.

3. **Debugging complex import flows**: Use targeted debugging output to trace resource processing through multiple importers within the same import session.

4. **Test coverage for edge cases**: The specific scenario of "same source file, different importer" within one import session required explicit testing.

5. **Refactoring for maintainability**: Long, repetitive functions with embedded logic are harder to debug and test. Extract focused helper functions for complex operations like source file merging.

**Testing verification**: After fix, cell `1,-13` correctly shows `["Morrowind.esm", "Tribunal.esm"]` after importing both files, proving proper source file accumulation across multiple data files and import stages.

## Source File Tracking Bug: Replacement Instead of Merging

### Problem: Source File IDs Being Replaced Instead of Merged
When importing multiple data files that contain the same record, the source_file_ids were being replaced rather than merged. For example, after importing Morrowind.esm and then Tribunal.esm, cell `1,-13` had `source_file_ids: ["Tribunal.esm"]` instead of the expected `["Morrowind.esm", "Tribunal.esm"]`.

### Root Cause Analysis
The issue was caused by records being processed twice during the same import operation:

1. **First processing**: Cell importer processes the cell and correctly sets source_file_ids
2. **Second processing**: CellReference importer processes the same cell again for relationship management

During the second processing, the source file tracking logic had two bugs:

#### Bug 1: Significant Change Path Not Preserving Existing Source Files
In the "significant change" code path, when `is_new_source` was `false`, the code was using the record's source_file_ids as-is instead of preserving existing source file IDs:

```elixir
data =
  if is_new_source do
    Map.update!(record, :source_file_ids, &(existing_record.source_file_ids ++ &1))
  else
    record  # BUG: This only contains the new source file ID
  end
```

#### Bug 2: Same File Processed Multiple Times in Single Import
During a single import (e.g., Tribunal.esm):
- Cell importer processes cell `1,-13` and merges: `["Morrowind.esm"] + ["Tribunal.esm"] = ["Morrowind.esm", "Tribunal.esm"]`
- CellReference importer processes the same cell again with `is_new_source = false` (since "Tribunal.esm" is already in the list)
- The second processing overwrote the correctly merged list with just `["Tribunal.esm"]`

### Solution: Always Merge Source File IDs Properly
Fixed the source file ID merging logic to always preserve existing source file IDs, regardless of the processing path:

```elixir
# Always merge source file IDs properly, regardless of whether it's a new source
merged_source_ids = 
  if is_new_source do
    existing_record.source_file_ids ++ record.source_file_ids
  else
    # Even if not a new source, we need to preserve existing source file IDs
    # and make sure the current source file ID is in the list
    current_ids = existing_record.source_file_ids || []
    if source_file_id in current_ids do
      current_ids
    else
      current_ids ++ [source_file_id]
    end
  end

data = Map.put(record, :source_file_ids, merged_source_ids)
```

### Verification Process
Used debugging output to trace the source file tracking through both processing phases:

1. **First processing (Cell importer)**: Correctly merged source files
2. **Second processing (CellReference importer)**: Previously overwrote, now preserves merged list

**Result**: Cell `1,-13` now correctly shows `source_file_ids: ["Morrowind.esm", "Tribunal.esm"]` after importing both files.

### Key Learnings
1. **Multiple Processing Phases**: Some records get processed multiple times during import (once for the record itself, once for relationships). Source tracking must handle this correctly</edits>