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
- Next: REPA (Repair items) - Similar simple item structure
- Then: LOCK, PROB - Also simple items
- Continue with asset objects (STAT, ACTI, LIGH)