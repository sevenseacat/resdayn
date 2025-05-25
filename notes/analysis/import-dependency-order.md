# Import Dependency Order Analysis

## Currently Imported Records

The following records are already imported and available as dependencies:

- `TES3` (Main header)
- `GMST` (Game settings)
- `GLOB` (Global variables)
- `CLAS` (Character classes)
- `FACT` (Factions)
- `RACE` (Races)
- `SOUN` (Sound effects)
- `SKIL` (Skills)
- `MGEF` (Magic effects)
- `SCPT` (Scripts)
- `SPEL` (Spells)
- `ENCH` (Enchanting effects)
- `INGR` (Ingredients)

## Remaining Records to Import (in dependency order)

### Tier 1: No Dependencies (Can be imported immediately)

These records have no dependencies on other records or only reference already-imported records:

1. **`REGN` (Regions)** - References sounds by ID (already imported)
2. **`BSGN` (Birth signs)** - Self-contained with special_ids references
3. **`LTEX` (Land textures)** - Self-contained
4. **`STAT` (Static objects)** - Self-contained
5. **`BODY` (Body parts)** - Self-contained
6. **`MISC` (Miscellaneous items)** - Self-contained
7. **`REPA` (Repair items)** - Self-contained
8. **`ACTI` (Activators)** - May reference scripts (already imported)
9. **`APPA` (Alchemy apparatus)** - Self-contained
10. **`LOCK` (Lockpicking items)** - Self-contained
11. **`PROB` (Probe items)** - Self-contained
12. **`ALCH` (Potions)** - Self-contained
13. **`LIGH` (Lights)** - May reference scripts (already imported)

### Tier 2: Depends on Tier 1 Records

14. **`DOOR` (Doors)** - May reference scripts (already imported)
15. **`CONT` (Containers)** - May reference scripts (already imported)
16. **`WEAP` (Weapons)** - References enchantments and scripts (both already imported)
17. **`ARMO` (Armour)** - References enchantments and scripts (both already imported)
18. **`CLOT` (Clothing)** - Likely references enchantments and scripts (both already imported)
19. **`BOOK` (Books and papers)** - References enchantments, scripts, and skills (all already imported)

### Tier 3: Complex Entities

20. **`CREA` (Creatures)** - References spells, scripts, and sounds (all already imported)
21. **`NPC_` (NPCs)** - References races, classes, factions, spells, and scripts (all already imported)

### Tier 4: Levelled Lists (Depend on Tier 2-3)

22. **`LEVI` (Levelled items)** - References items from Tier 1-2
23. **`LEVC` (Levelled creatures)** - References creatures from Tier 3

### Tier 5: World Structure

24. **`CELL` (Cells)** - References various objects from previous tiers

### Tier 6: Dialogue System

25. **`DIAL` (Dialogue/journal topics)** - Self-contained
26. **`INFO` (Dialogue records)** - Depends on DIAL topics
27. **`INFO` (Journal records)** - Depends on DIAL topics

## Recommended Import Order

Based on the dependency analysis, the recommended import order is:

**Phase 1 (Immediate):**
1. BSGN ✓, STAT ✓, BODY ✓, MISC ✓, REPA ✓, ACTI ✓, APPA ✓, LOCK ✓, PROB ✓, ALCH ✓, LIGH ✓

**Phase 2 (After Phase 1):**
2. DOOR ✓, WEAP ✓, ARMO, CLOT ✓, BOOK ✓

**Phase 3 (After Phase 2):**
3. CREA, NPC_

**Phase 4 (After Phase 3):**
4. LEVI, LEVC, SNDG

**Phase 5 (After Phase 4):**
5. REGN, CONT

**Phase 6 (After Phase 5):**
6. CELL, DIAL, then INFO (both dialogue and journal)

## Notes

- Most Tier 1 records can be imported in parallel as they have no inter-dependencies
- WEAP, ARMO, CLOT, and BOOK depend on already-imported ENCH and SCPT records
- NPCs and Creatures are complex entities with multiple dependencies but all prerequisites are already imported
- Levelled lists must come after the items/creatures they reference
- Cells reference many different object types, so should come near the end
- Dialogue system is mostly self-contained and can be imported last
