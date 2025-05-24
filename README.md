# Resdayn

The end goal is to create a read-only webapp to present game data used in Morrowind.

Using the amazing work of Dave Humphrey detailed here: http://www.uesp.net/morrow/tech/mw_esm.txt and here: https://en.uesp.net/wiki/Morrowind_Mod:Mod_File_Format

## The Long-Term Plan

- Parse the ESM data file into a meaningful format
- Build Ash resources using the parsed data
- Use the resources to build an auto-generated admin area to manage the data

## Record Types

| Parsed | Imported | Name |
| :---:  | :---:    | :--: |
| ✓      | ✓        | `TES3` (Main header) |
| ✓      | ✓        | `GMST` (Game settings) |
| ✓      | ✓        | `GLOB` (Global variable) |
| ✓      | ✓        | `CLAS` (Character classes) |
| ✓      | ✓        | `FACT` (Factions) |
| ✓      | ✓        | `RACE` (Races) |
| ✓      | ✓        |` SOUN` (Sound effects) |
| ✓      | ✓        | `SKIL` (Skills) |
| ✓      | ✓        | `MGEF` (Magic effects) |
| ✓      | ✓        | `SCPT` (Scripts) |
| ✓      |          | `REGN` (Regions) |
| ✓      | ✓        | `BSGN` (Birth signs) |
| ✓      | x        | `LTEX` (Land textures) |
| ✓      | ✓        | `STAT` (Static objects) |
| ✓      |          | `DOOR` (Doors) |
| ✓      | ✓        | `MISC` (Miscellaneous items) |
| ✓      |          | `WEAP` (Weapons) |
| ✓      |          | `CONT` (Containers) |
| ✓      | ✓        | `SPEL` (Spells) |
| ✓      |          | `CREA` (Creatures) |
| ✓      | ✓        | `BODY` (Body parts) |
| ✓      | ✓        | `LIGH` (Lights) |
| ✓      | ✓        | `ENCH` (Enchanting effects) |
| ✓      |          | `NPC_` (NPCs) |
| ✓      |          | `ARMO` (Armour) |
| ✓      |          | `CLOT` (Clothing) |
| ✓      | ✓        | `REPA` (Repair items) * |
| ✓      | ✓        | `ACTI` (Activators) |
| ✓      | ✓        | `APPA` (Alchemy apparatus) |
| ✓      | ✓        | `LOCK` (Lockpicking items) * |
| ✓      | ✓        | `PROB` (Probe items) * |
| ✓      | ✓        | `INGR` (Ingredients) |
| ✓      |          | `BOOK` (Books and papers) |
| ✓      | ✓        | `ALCH` (Potions) |
| ✓      |          | `LEVI` (Levelled items) |
| ✓      |          | `LEVC` (Levelled creatures) |
| ✓      |          | `CELL` (Cells) |
| x      |          | `LAND` (Landscapes) |
| x      |          | `PGRD` (Path grids) |
| ✓      |          | `DIAL` (Dialogue/journal topics) |
| ✓      |          | `INFO` (Dialogue records) |
| ✓      |          | `INFO` (Journal records) |

## Implementation Notes

\* REPA, LOCK, and PROB records are consolidated into a single `Tool` resource with a `tool_type` discriminator field, as they share identical data structures and serve related purposes.

## Other Features to Add

* Ability to import multiple files (eg. see data from Morrowind.esm + Tribunal.esm + Bloodmoon.esm)
