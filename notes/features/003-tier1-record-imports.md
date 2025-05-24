# Feature 003: Tier 1 Record Imports

## Plan

### Overview
Implement importers for all 13 Tier 1 record types that have no dependencies or only reference already-imported records. These can be implemented in parallel and will provide the foundation for more complex record types in later tiers.

### Record Types to Implement

1. **REGN (Regions)** - Weather data, map colors, ambient sounds
2. **BSGN (Birth signs)** - Character birth signs with special abilities
3. **LTEX (Land textures)** - Terrain texture definitions
4. **STAT (Static objects)** - Non-interactive world objects
5. **BODY (Body parts)** - Character/creature body part definitions
6. **MISC (Miscellaneous items)** - General items without specific category
7. **REPA (Repair items)** - Items used to repair equipment
8. **ACTI (Activators)** - Interactive world objects
9. **APPA (Alchemy apparatus)** - Equipment for alchemy crafting
10. **LOCK (Lockpicking items)** - Tools for lockpicking
11. **PROB (Probe items)** - Tools for disarming traps
12. **ALCH (Potions)** - Consumable alchemy products
13. **LIGH (Lights)** - Light sources (torches, lanterns, etc.)

### Implementation Strategy

#### Step 1: Create Ash Resources (Codex)
For each record type, create appropriate Ash resources in the codex structure:
- Determine the logical domain (Assets, Items, Mechanics, Characters)
- Create resource modules with appropriate attributes
- Define relationships where applicable

#### Step 2: Create Importer Modules
For each record type, create an importer module following the existing pattern:
- Use `Resdayn.Importer.Record` behavior
- Map parser data to resource attributes
- Handle flags and special transformations
- Reference the appropriate codex resource

#### Step 3: Resource Domain Organization
Group resources by logical domain:

**Assets Domain:**
- REGN → `Resdayn.Codex.Assets.Region`
- LTEX → `Resdayn.Codex.Assets.LandTexture`
- STAT → `Resdayn.Codex.Assets.StaticObject`
- LIGH → `Resdayn.Codex.Assets.Light`

**Items Domain:**
- MISC → `Resdayn.Codex.Items.MiscellaneousItem`
- REPA → `Resdayn.Codex.Items.RepairItem`
- APPA → `Resdayn.Codex.Items.AlchemyApparatus`
- LOCK → `Resdayn.Codex.Items.Lockpick`
- PROB → `Resdayn.Codex.Items.Probe`
- ALCH → `Resdayn.Codex.Items.Potion`

**Characters Domain:**
- BSGN → `Resdayn.Codex.Characters.Birthsign`
- BODY → `Resdayn.Codex.Characters.BodyPart`

**Assets Domain (Interactive):**
- ACTI → `Resdayn.Codex.Assets.Activator`

#### Step 4: Implementation Order
Implement in this sequence to validate the pattern works:

1. **Simple items first** (MISC, REPA, LOCK, PROB) - Basic item structure
2. **Asset objects** (STAT, ACTI, LIGH) - Static world objects
3. **Complex items** (APPA, ALCH) - Items with special properties
4. **Character-related** (BSGN, BODY) - Character system extensions
5. **World assets** (REGN, LTEX) - World/environment data

#### Step 5: Testing Strategy
For each implemented record type:
- Verify parser data is correctly mapped to resource attributes
- Test flag transformations work correctly
- Validate that records can be imported without errors
- Check that the data appears correctly in any admin interfaces

### Technical Considerations

#### Database Schema
- Most records will need basic fields: id, name, description
- Items will need value, weight, icon fields
- Some records have complex nested data (weather patterns, body part types)
- Consider index needs for frequently queried fields

#### Flag Handling
- Many records have bitfield flags that need proper transformation
- Use existing `with_flags` helper pattern
- Document flag meanings for future reference

#### Reference Integrity
- REGN references sound IDs (already imported)
- ACTI and LIGH may reference script IDs (already imported)
- Validate these references exist during import

#### Parser Data Mapping
- Review each parser module to understand the complete data structure
- Handle optional fields gracefully
- Transform enums and constants to meaningful values

### Deliverables

1. **13 Ash Resource modules** in appropriate codex domains
2. **13 Importer modules** following established patterns
3. **Database migrations** for each new resource type
4. **Updated import process** to include all Tier 1 records
5. **Basic validation** that all records import successfully

### Success Criteria

- All 13 record types can be parsed and imported without errors
- Data integrity is maintained (no missing required fields)
- Resources are properly organized in logical domains
- Import performance remains acceptable
- Foundation is established for Tier 2 record implementation

### Dependencies

- Existing parser modules (already implemented)
- Current importer infrastructure
- Ash framework and codex structure
- Database setup and migration system

This plan establishes the foundation for importing the majority of remaining record types and validates the patterns needed for more complex records in subsequent tiers.

## Log

### MISC (Miscellaneous Items) - COMPLETED ✓

**Implementation Details:**
- Created `Resdayn.Codex.Items.MiscellaneousItem` resource
- Created `Resdayn.Importer.Record.MiscellaneousItem` importer
- Added to `Resdayn.Codex.Items` domain
- Generated migration with `mix ash.codegen create_miscellaneous_items`
- Added to import task in `lib/mix/tasks/resdayn/import_codex.ex`

**Key Findings:**
1. **Optional Fields:** Parser data may have optional fields (like `script_id`) - use `Map.take/2` to handle gracefully
2. **Field Mapping:** Parser uses `nif_model` and `icon_filename`, resource expects `nif_model_filename` and `icon_filename`
3. **Migration Process:** Use `mix ash.codegen <migration_name>` then `mix ecto.migrate`
4. **Testing:** Use `mix resdayn.import_codex Morrowind.esm <RecordType>` for single record testing
5. **Success Metrics:** Successfully imported 536 miscellaneous items from Morrowind.esm

**Refined Pattern for Remaining Records:**
1. Examine parser structure for field names and optional fields
2. Create Ash resource with proper field mapping
3. Create importer using `Map.take/2` for all relevant fields
4. Add to appropriate domain
5. Generate migration with descriptive name
6. Add to import task list
7. Test with single record type import

**Updated Implementation Order:**
- ✓ MISC (Miscellaneous items) - COMPLETED
- ✓ TOOL (Repair items, Lockpicks, Probes) - COMPLETED (Consolidated)
- ✓ APPA (Alchemy apparatus) - COMPLETED
- ✓ ALCH (Potions) - COMPLETED
- Next: Asset objects (STAT, ACTI, LIGH)
- Finally: Character-related (BSGN, BODY) and World assets (REGN, LTEX)

### REPA (Repair Items) - COMPLETED ✓

**Implementation Details:**
- Created `Resdayn.Codex.Items.RepairItem` resource
- Created `Resdayn.Importer.Record.RepairItem` importer
- Added to `Resdayn.Codex.Items` domain
- Generated migration with `mix ash.codegen create_repair_items`
- Added to import task in `lib/mix/tasks/resdayn/import_codex.ex`

**Key Findings:**
1. **Flags Conflict:** The `Importable` extension automatically adds a `flags` attribute, so manual definition causes conflicts
2. **Repair-Specific Fields:** Parser provides repair-specific data (uses, quality) in addition to standard item fields
3. **Field Structure:** Parser maps `nif_model` → `nif_model_filename` and `icon` → `icon_filename`
4. **Import Success:** Successfully imported 6 repair items from Morrowind.esm
5. **Pattern Consistency:** Follows same successful pattern as MISC implementation

**Technical Details:**
- Uses standard item attributes: id, name, weight, value
- Adds repair-specific attributes: uses (integer), quality (float)
- Maintains script relationship for interactive repair items
- Parser structure: `RIDT` chunk contains packed binary data for weight/value/uses/quality

**Validation:**
- All 6 repair items imported without errors
- Database schema properly created with repair-specific fields
- Field mapping correctly transforms parser data to resource attributes
- No foreign key constraint violations

### TOOL (Repair Items, Lockpicks, Probes) - CONSOLIDATED ✓

**Major Refactoring Decision:**
After analyzing parser structures for REPA, LOCK, and PROB records, discovered they have identical field structures:
- Common fields: id, name, nif_model, icon, script_id, weight, value, quality, uses
- Only difference: data chunk names (RIDT, LKDT, PBDT) and field order in binary
- Small dataset: 6 records each = 18 total records

**Consolidation Implementation:**
- Refactored RepairItem into consolidated `Resdayn.Codex.Items.Tool` resource
- Added `tool_type` discriminator field with values: `:repair_item`, `:lockpick`, `:probe`
- Created unified `Resdayn.Importer.Record.Tool` importer handling all three parser types
- Removed duplicate RepairItem resource and migration files
- Single database table `tools` with tool_type column for efficient storage

**Technical Benefits:**
1. **Eliminated Code Duplication:** 3 resources → 1, 3 importers → 1
2. **Efficient Storage:** No wasted columns, single table for related data
3. **Simplified Maintenance:** Single codebase to maintain for similar functionality
4. **Clean Architecture:** Logical grouping of conceptually related items

**Import Results:**
- Successfully imported all 18 tools from Morrowind.esm:
  - 6 repair items (e.g., "Sirollus Saccus' Hammer")
  - 6 lockpicks (e.g., "The Skeleton Key")
  - 6 probes (e.g., "Secret Master's Probe")
- All tools properly categorized by tool_type
- Database schema optimal for querying and filtering

**Pattern Established:**
This consolidation validates that when record types share identical structures and serve related purposes, consolidation with discriminator fields is preferable to separate resources, especially for small datasets in legacy games with no future expansions.

### APPA (Alchemy Apparatus) - COMPLETED ✓

**Implementation Details:**
- Created `Resdayn.Codex.Items.AlchemyApparatus` resource (separate from Tools)
- Created `Resdayn.Importer.Record.AlchemyApparatus` importer
- Added to `Resdayn.Codex.Items` domain
- Generated migration with `mix ash.codegen create_alchemy_apparatus`
- Added to import task in `lib/mix/tasks/resdayn/import_codex.ex`

**Key Findings:**
1. **Distinct from Tools:** Although similar structure (weight, value, quality), APPA lacks `uses` field and has different semantic purpose
2. **Apparatus Types:** Four distinct types with good distribution: mortar_and_pestle, alembic, calcinator, retort
3. **Quality Ranges:** Wide quality range from 0.15 (basic) to 2.0 (master level equipment)
4. **Import Success:** Successfully imported 22 alchemy apparatus from Morrowind.esm
5. **Type Distribution:** 7 alembics, 5 each of mortar/pestle, calcinators, and retorts

**Technical Details:**
- Uses `apparatus_type` atom field with constrained values for the four alchemy equipment types
- Parser provides type mapping from numeric codes to meaningful atom values
- Standard item attributes: id, name, weight, value, plus alchemy-specific quality
- Parser structure: `AADT` chunk contains packed binary data for type/quality/weight/value

**Architectural Decision:**
Kept APPA as separate resource rather than consolidating with Tools because:
- Different field structure (no `uses` field)
- Different semantic domain (crafting equipment vs utility tools)
- Larger dataset (22 vs 18 records)
- Distinct apparatus type categories requiring specific constraints

**Validation:**
- All 22 alchemy apparatus imported without errors
- Proper type distribution across all four apparatus categories
- Quality values correctly parsed from binary data
- No foreign key constraint violations

**Examples by Type:**
- Mortar & Pestle: "SecretMaster's Mortar and Pestl" (quality: 2.0)
- Alembic: "Tsiya's Skooma Pipe" (quality: 0.15)
- Calcinator: "SecretMaster's Calcinator" (quality: 2.0)  
- Retort: "SecretMaster's Retort" (quality: 2.0)

### ALCH (Potions) - COMPLETED ✓

**Implementation Details:**
- Created `Resdayn.Codex.Items.Potion` resource with embedded magical effects
- Created `Resdayn.Codex.Items.Potion.Effect` embedded resource for magical effects
- Created `Resdayn.Codex.Items.Potion.Range` enum for effect targeting
- Created `Resdayn.Importer.Record.Potion` importer
- Added to `Resdayn.Codex.Items` domain
- Generated migration with `mix ash.codegen create_potions`
- Added to import task in `lib/mix/tasks/resdayn/import_codex.ex`

**Key Findings:**
1. **Complex Magical Effects:** Potions have arrays of magical effects similar to spells and enchantments
2. **Effect Structure:** Each effect has duration, magnitude (min/max), range, area, and references to magic effects/attributes/skills
3. **Large Dataset:** 258 potions imported from Morrowind.esm
4. **Effect Distribution:** Most potions (236) have 1 effect, complex ones like Skooma have up to 6 effects
5. **Manual Crafting:** All potions are manually crafted (autocalc: false), showing careful game design

**Technical Details:**
- Uses embedded `Effect` resources to store magical effect arrays in JSONB
- Effect structure mirrors spell/enchantment effects for consistency
- Parser provides complex effect data with magic_effect_id, attribute_id, skill_id references
- `autocalc` flag extracted from parser flags (all false in Morrowind.esm)
- Parser structure: `ALDT` chunk for basic data, `ENAM` chunks for magical effects

**Architectural Consistency:**
- Follows established pattern from Spell and Enchantment effects
- Uses embedded resources for complex nested data
- Maintains referential integrity to MagicEffect, Attribute, and Skill resources
- Range enum consistent with other magical effect systems

**Import Results:**
- Successfully imported all 258 potions without errors
- Effect counts: 1 effect (236), 2 effects (17), 3 effects (3), 4 effects (1), 6 effects (1)
- Value range: 5 gold (bargain potions) to 500 gold (Skooma)
- Complex examples: Skooma with 4 effects using magic effects 17 and 79
- **Range analysis**: All 289 potion effects are `:self` range - no `:touch` or `:target` effects found

**Examples:**
- Simple: "Bargain Fortify Willpower" (5 gold, 1 effect)
- Complex: "Skooma" (500 gold, 4 effects with 60-second duration)
- Quality range: "Cheap" to "Exclusive" indicating different potency levels

**Validation:**
- All 258 potions imported without errors
- Magical effects properly structured and stored as JSONB
- Foreign key relationships maintained for magic effects, attributes, skills
- Effect data correctly mapped from parser enchantment structure

**Game Design Insight:**
Analysis reveals that **all potion effects in Morrowind are self-targeted** (289 effects across 258 potions). This makes logical sense:
- Potions are consumed, not cast at targets
- No thrown or projectile potions exist in the base game
- Consistent with Elder Scrolls lore where potions affect the drinker directly

While our architecture supports `:touch` and `:target` ranges for consistency with spells/enchantments, potions will never use these values in practice. This validates our decision to maintain consistent magical effect structure across all systems, even if some fields remain unused for specific item types.

### Refactoring: Shared MagicRange and Magnitude Types ✓

**Post-Implementation Refactoring:**
After implementing ALCH (Potions), identified code duplication and inconsistency in magical effect systems:

**Problems Identified:**
1. **Duplicate Range Enums:** Three identical range enums with `[:self, :touch, :target]`
   - `Resdayn.Codex.Mechanics.Spell.Range`
   - `Resdayn.Codex.Mechanics.Enchantment.Range`  
   - `Resdayn.Codex.Items.Potion.Range`
2. **Inconsistent Magnitude Types:**
   - Spell effects: `:map` type
   - Enchantment effects: `:range` type (builtin)
   - Potion effects: `:map` type (copied from spells)

**Refactoring Implementation:**
1. **Created shared `Resdayn.Codex.MagicRange`** enum for all magical effect targeting
2. **Standardized magnitude type** to builtin `:range` type across all effect systems
3. **Updated all Effect resources** to use shared types:
   - `Resdayn.Codex.Mechanics.Spell.Effect`
   - `Resdayn.Codex.Mechanics.Enchantment.Effect`
   - `Resdayn.Codex.Items.Potion.Effect`
4. **Enhanced Range type** to handle legacy map format for backward compatibility
5. **Removed duplicate range files** - eliminated 3 duplicate enum definitions

**Technical Benefits:**
- **Single source of truth** for magical effect ranges
- **Consistent magnitude handling** across all magical systems
- **Reduced code duplication** - 3 range enums → 1 shared enum
- **Type safety** - builtin `:range` type with proper validation
- **Backward compatibility** - existing data continues to work

**Migration Handling:**
- No database migration required (JSONB storage compatible)
- Enhanced `Resdayn.Codex.Range.cast_stored/2` to handle legacy `%{"min" => x, "max" => y}` format
- All existing magical effects continue to work seamlessly

**Validation:**
- All tests pass after refactoring
- Existing spell and potion data loads correctly
- Fresh imports use consistent type format
- No breaking changes to existing functionality

This refactoring establishes a clean, consistent foundation for all magical effect systems in the codebase.